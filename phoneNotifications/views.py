from django.shortcuts import render
from datetime import datetime
from django.contrib.sites.models import Site
from django.http import HttpResponseBadRequest, HttpResponse
from django.views.decorators.csrf import csrf_exempt
from push_notifications.models import APNSDevice, GCMDevice
import json
import requests

ASBase_url = "http://russet.ischool.berkeley.edu:8080"

subscriber_id = "Seating Reservation Result Notification System"
subscriber_url = "http://" + Site.objects.all()[0].domain + "/reservation_result/"
# subscriber_url = "http://serene-wave-9290.herokuapp.com/reservation_result/"
subscription_id_deny = "DeniedReservationSubscription"
subscription_id_approve = "ApprovedReservationSubscription"
subscription_actor_text = "Reserversion Result"


@csrf_exempt
def register_device(response):
	print response.body
	if response.method == "POST":
		device_json = json.loads(response.body)
		print json.dumps(device_json)

		device_token = device_json["device_token"]
		# apns_token = '4aed6b088ae45079d9788e692af58446c9a14efb80190a936050aa0cbbd458f9'

		if device_token == "":	
			# TODO: bad request content
			return HttpResponseBadRequest("<h1>Bad Request</h1><p>Requested object is not managed by us.</p>")

		try:
			device = APNSDevice.objects.get(registration_id=device_token)
			# TOOD: request content: already registered
		except APNSDevice.DoesNotExist:
			device = APNSDevice.objects.create(name='Pi-Tan-iPhone', registration_id=device_token)
			# TOOD: request content: successfully registered

		# headers = {'Content-Type': 'application/stream+json'}
		# r = requests.post(ASBase_url + "/activities/", data=json.dumps(activity_response), headers=headers)
		# print r.content
		# return HttpResponse(r.content)
	else:
		# TODO: make it json 
		return HttpResponseBadRequest("<h1>Bad Request</h1><p>The server only supports POSTs.</p>")

# TODO: 
# 1. create a specific extra field for device(for sending notifiction)
# 2. add the filed to new_request response to specify the device
# 3. send result to device: deny/approve result with device token(query device from device id) 
@csrf_exempt
def reservation_result(response):
	print 'test'

	# device = GCMDevice.objects.get(registration_id=gcm_reg_id)
	# # The first argument will be sent as "message" to the intent extras Bundle
	# # Retrieve it with intent.getExtras().getString("message")
	# device.send_message("You've got mail")
	# # If you want to customize, send an extra dict and a None message.
	# # the extras dict will be mapped into the intent extras Bundle.
	# # For dicts where all values are keys this will be sent as url parameters,
	# # but for more complex nested collections the extras dict will be sent via
	# # the bulk message api.
	# device.send_message(None, extra={"foo": "bar"})

	apns_token = '4aed6b088ae45079d9788e692af58446c9a14efb80190a936050aa0cbbd458f9'
	try:
		device = APNSDevice.objects.get(registration_id=apns_token)
	except APNSDevice.DoesNotExist:
		device = APNSDevice.objects.create(name='Pi-Tan-iPhone', registration_id=apns_token)
	device.send_message("You've got mail") # Alert message may only be sent as text.
	device.send_message(None, badge=5) # No alerts but with badge.
	device.send_message(None, badge=1, extra={"foo": "bar"}) # Silent message with badge and added custom data.

	# print response.body
	# if response.method == "POST":
	# 	activity_json = json.loads(response.body)
	# 	print json.dumps(activity_json)
	# 	# Reject activity if it is not a request
	# 	if activity_json["verb"] != "request":
	# 		return HttpResponseBadRequest("<h1>Bad Request</h1><p>Input was not a request activity.</p>")

	# 	# Reject activity if it is not under our management
	# 	if subscription_actor_text not in activity_json["object"]["displayName"]:
	# 		return HttpResponseBadRequest("<h1>Bad Request</h1><p>Requested object is not managed by us.</p>")

	# 	activity_response = {}
	# 	activity_response["actor"] = {"displayName": subscriber_id, "id": subscriber_url}
	# 	activity_response["verb"] = "deny"
	# 	activity_response["reason"] = "Your request has been noted, but these seats are not reservable."
	# 	activity_response["object"] = activity_json
	# 	activity_response["published"] = datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ")

	# 	headers = {'Content-Type': 'application/stream+json'}
	# 	r = requests.post(ASBase_url + "/activities/", data=json.dumps(activity_response), headers=headers)
	# 	print r.content
	# 	return HttpResponse(r.content)
	# else:
	# 	return HttpResponseBadRequest("<h1>Bad Request</h1><p>The server only supports POSTs.</p>")

def create_phone_notifications_subscriber(response):
	subscribe_url = ASBase_url + "/users"
	r = requests.get(subscribe_url)
	users = r.json()
	if subscriber_id in users["userIDs"]:
		# Code to clean up stale subscribers
		# r = requests.delete (subscribe_url + "/" + subscriber_id)
		return HttpResponse('"' + subscriber_id + '" is already subscribed to ' + ASBase_url)
	else:
		subscriber = {}
		subscriber["userID"] = subscriber_id
		subscriber["channels"] = [{"type": "URL_Callback", "data": subscriber_url}]

		headers = {'Content-Type': 'application/json'}
		r = requests.post (subscribe_url, data=json.dumps(subscriber), headers=headers)
		return HttpResponse(r.content)

def create_deny_reservation_subscription(response):
	# create_subscription_by_verb(response, 'deny', subscription_id_deny)
	verb = 'deny'
	subscription_id = subscription_id_deny

	subscription_url = ASBase_url + "/users/" + subscriber_id + "/subscriptions"
	r = requests.get(subscription_url) # requests takes care of encoding
	subscriptions = r.json()
	print json.dumps(subscriptions)

	if subscription_id in subscriptions["subscriptionIDs"]:
		# Code to clean up stale subscriptions
		# r = requests.delete (subscription_url + "/" + subscription_id)
		# print r.content
		return HttpResponse('"' + subscription_id + '" subscription already exists')
	else:
		subscription = {}
		subscription["userID"] = subscriber_id
		subscription["subscriptionID"] = subscription_id
		subscription["ASTemplate"] = {}
		subscription["ASTemplate"]["object.displayName"] = { "$regex":  ".*" + subscription_actor_text + ".*" }
		subscription["ASTemplate"]["verb"] = { "$in": [verb] }

		headers = {'Content-Type': 'application/json'}
		r = requests.post (subscription_url, data=json.dumps(subscription), headers=headers)
		return HttpResponse(r.content)

def create_approve_reservation_subscription(response):
	# create_subscription_by_verb(response, 'approve', subscription_id_approve)

	verb = 'approve'
	subscription_id = subscription_id_approve

	subscription_url = ASBase_url + "/users/" + subscriber_id + "/subscriptions"
	r = requests.get(subscription_url) # requests takes care of encoding
	subscriptions = r.json()
	print json.dumps(subscriptions)

	if subscription_id in subscriptions["subscriptionIDs"]:
		# Code to clean up stale subscriptions
		# r = requests.delete (subscription_url + "/" + subscription_id)
		# print r.content
		return HttpResponse('"' + subscription_id + '" subscription already exists')
	else:
		subscription = {}
		subscription["userID"] = subscriber_id
		subscription["subscriptionID"] = subscription_id
		subscription["ASTemplate"] = {}
		subscription["ASTemplate"]["object.displayName"] = { "$regex":  ".*" + subscription_actor_text + ".*" }
		subscription["ASTemplate"]["verb"] = { "$in": [verb] }

		headers = {'Content-Type': 'application/json'}
		r = requests.post (subscription_url, data=json.dumps(subscription), headers=headers)
		return HttpResponse(r.content)

# def create_subscription_by_verb(response, verb, subscription_id):
# 	subscription_url = ASBase_url + "/users/" + subscriber_id + "/subscriptions"
# 	r = requests.get(subscription_url) # requests takes care of encoding
# 	subscriptions = r.json()
# 	print json.dumps(subscriptions)

# 	if subscription_id in subscriptions["subscriptionIDs"]:
# 		# Code to clean up stale subscriptions
# 		# r = requests.delete (subscription_url + "/" + subscription_id)
# 		# print r.content
# 		return HttpResponse('"' + subscription_id + '" subscription already exists')
# 	else:
# 		subscription = {}
# 		subscription["userID"] = subscriber_id
# 		subscription["subscriptionID"] = subscription_id
# 		subscription["ASTemplate"] = {}
# 		subscription["ASTemplate"]["object.displayName"] = { "$regex":  ".*" + subscription_actor_text + ".*" }
# 		subscription["ASTemplate"]["verb"] = { "$in": [verb] }

# 		headers = {'Content-Type': 'application/json'}
# 		r = requests.post (subscription_url, data=json.dumps(subscription), headers=headers)
# 		return HttpResponse(r.content)
