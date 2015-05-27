require "bunny"
require "thread"
require "json"

conn = Bunny.new(:automatically_recover => false)
conn.start

@ch   = conn.create_channel

class RMQ
  attr_reader :reply_queue
  attr_accessor :response, :call_id
  attr_reader :lock, :condition

  def initialize(ch, server_queue)
    @ch             = ch
    @x              = ch.default_exchange

    @server_queue   = server_queue
    @reply_queue    = ch.queue("client.two", :exclusive => true)

    @lock      = Mutex.new
    @condition = ConditionVariable.new
    that       = self

    @reply_queue.subscribe do |delivery_info, properties, payload|
      if properties[:correlation_id] == that.call_id
        that.response = payload
        that.lock.synchronize{that.condition.signal}
      end
    end
  end

  def send(text)
    self.call_id = self.generate_uuid

    @x.publish(text,
      :routing_key    => @server_queue,
      :correlation_id => call_id,
      :reply_to       => @reply_queue.name)

    lock.synchronize{condition.wait(lock)}
    puts response
  end

  protected

  def generate_uuid 
    "#{rand}#{rand}#{rand}"
  end
end

client   = RMQ.new(@ch, "client.one")
@send_text = gets.chomp
response = client.send({:message=>@send_text}.to_json)







