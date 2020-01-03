module AsyncCable
  module Util
    # @param parent [Async::Task,NilClass] parent task for new one.
    # @param schedule [Boolean] run now if true, otherwise will be run at next reactor loop cycle.
    # @return [Async::Task] return created task.
    def create_task(parent = Async::Task.current?, schedule = false, &block)
      task = Async::Task.new(parent, &block)
      if schedule
        Async::Task.current.reactor << task.fiber
      else
        task.run
      end
      task
    end

    # Each yield will be executed within it's own fiber.
    # @param list [Array] list that will be iterable.
    # @param args [Array] parent, schedule @see #create_task (optional).
    def each_async(list, *args)
      list.each do |item|
        create_task(*args) { yield item }
      end
    end

    module_function :create_task, :each_async
  end
end
