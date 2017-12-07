module AsyncTask
  class InvalidStateError < StandardError; end

  module BaseAttempt
    extend ActiveSupport::Concern

    included do
      extend Enumerize

      self.table_name = 'async_task_attempts'

      attr_readonly :idempotence_token
      attr_readonly :target
      attr_readonly :method_name
      attr_readonly :method_args
      attr_readonly :encryptor

      validates :target, presence: true
      validates :method_name, presence: true
      validates :encryptor, presence: true

      serialize :method_args

      enumerize :status,
                in: %i[pending succeeded failed expired],
                predicates: true

      scope :pending, -> { where(status: :pending) }
      scope :succeeded, -> { where(status: :succeeded) }
      scope :failed, -> { where(status: :failed) }
      scope :expired, -> { where(status: :expired) }

      before_create do
        self.target = target.to_s
        self.status ||= 'pending'
        self.encryptor = (encryptor.presence || AsyncTask::NullEncryptor).to_s
      end

      def method_args
        return if super.blank?
        YAML.load(encryptor.constantize.decrypt(super))
      end

      def method_args=(args)
        super(encryptor.constantize.encrypt(args.to_yaml))
      end
    end

    def perform!
      return unless may_schedule?

      begin
        reload
        raise AsyncTask::InvalidStateError unless pending?
        increment!(:num_attempts)
      rescue ActiveRecord::StaleObjectError
        retry
      end

      with_lock do
        raise AsyncTask::InvalidStateError unless pending?

        if method_args.present?
          target.constantize.__send__(method_name, **method_args)
        else
          target.constantize.__send__(method_name)
        end

        update_status!('succeeded')
      end
    rescue StandardError => e
      handle_perform_error(e)
    end

    def expire!
      with_lock do
        raise AsyncTask::InvalidStateError unless pending?
        update_status!('expired')
      end
    end

    def fail!
      with_lock do
        raise AsyncTask::InvalidStateError unless pending?
        update_status!('failed')
      end
    end

    def may_schedule?
      scheduled_at.blank? || scheduled_at < Time.current
    end

    private

    # Does nothing, override this.
    def handle_perform_error(_e); end

    def update_status!(status)
      update!(status: status, completed_at: Time.current)
    end
  end
end
