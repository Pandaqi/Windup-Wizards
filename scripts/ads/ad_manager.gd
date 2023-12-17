extends Node

var admob = null
var active = false

var rewarded_id

func _ready():
	if not Global.is_mobile() or not Global.are_ads_enabled():
		active = false
		return
	
	active = true
	admob = AdMob.new()
	
	admob.is_real = Global.use_real_ads
	admob.rewarded_id = rewarded_id
	
	admob.child_directed = true
	admob.is_personalized = false
	admob.max_ad_content_rate = "G"
	
	# start by already loading an ad
	admob.load_rewarded_video()
	
	# listen to a few signals ourselves, for debugging
	# but most importantly: loading the NEXT ad when needed
	admob.connect("rewarded_video_closed", self, "rewarded_video_closed")
	admob.connect("rewarded", self, "rewarded")
	admob.connect("rewarded_video_failed_to_load", self, "rewarded_video_failed_to_load")
	
	print("AdMob started")

func is_active():
	return active

func rewarded_video_closed():
	admob.load_rewarded_video()

func rewarded(_currency, _amount):
	admob.load_rewarded_video()

func rewarded_video_failed_to_load(err):
	print(err)
	print("ERROR! Rewarded video failed to load")
	
	admob.load_rewarded_video()

func listen_for_signal(sig, obj, func_name):
	if not active: return
	
	admob.connect(sig, obj, func_name)



