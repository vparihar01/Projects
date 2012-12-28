# configuration allows a request every 5s from a single IP on the average in a 2 mins floating timeframe
WaitAMinute.lookback_interval = 2.minutes
WaitAMinute.maximum_requests = 120
WaitAMinute.debug = true		# leave traces in debug 
#WaitAMinute.layout = 'error'           # uncomment this line to enable the error layout; beware, rendering the view takes  ~900-1000ms! (iso ~10ms without a layout)
WaitAMinute.allowed_ips = ['127.0.0.1', '71.83.113.40']
