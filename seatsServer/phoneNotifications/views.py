from django.shortcuts import render
from datetime import datetime
from django.contrib.sites.models import Site
from django.core.exceptions import ObjectDoesNotExist
from django.http import HttpResponseBadRequest, HttpResponse
from django.views.decorators.csrf import csrf_exempt
from push_notifications.models import APNSDevice, GCMDevice
import json
import requests

ASBase_url = "http://russet.ischool.berkeley.edu:8080"

subscriber_id = "Seating Reservation Result Notification System"
subscriber_url = "http://" + Site.objects.all()[0].domain + "/reservation_result/"
subscription_id_deny = "DeniedReservationSubscription"
subscription_id_approve = "ApprovedReservationSubscription"
subscription_actor_text = "Reserversion Result"

# The end-user's app calls the /register_device endpoint, providing the following info in the POST body (required by the push module):
#
# { "device_token": "<tokenstring>", "system": <"iOS"|""> }
#
# Details on how GCM/APNS works with the push_notifications module here: https://pypi.python.org/pypi/django-push-notifications/1.2.0
#
# The GCM api key & APNS cert info are specified in seatsServer/settings.py:PUSH_NOTIFICATIONS_SETTINGS
@csrf_exempt
def register_device(request):
	response_json = {}
	print 'in_register_device'

	if request.method == "POST":
		device_json = json.loads(request.body)
		device_token = device_json["device_token"]
		system = device_json['system']

		print '====device info====='
		print 'request: ' + device_token
		print 'request: ' + system
		print '====device info end====='

		# TODO: error result: error code or status
		if device_token == "":
			print 'device token is not specified'
			# Didn't get device token
			response_json['message'] = 'The server did not receive device token'
			return HttpResponse(json.dumps(response_json), content_type="application/json")

		try:
			print 'try to find object in db'
			# This device is already registered.
			if system == 'iOS':
				print 'looking up iOS'
				device = APNSDevice.objects.get(registration_id=device_token)
			else:
				print 'looking up Android'
				device = GCMDevice.objects.get(registration_id=device_token)
			print device
			#device.delete() 

			#print 'delete object in db'
			response_json['message'] = 'This device is already registered.'

			return HttpResponse(json.dumps(response_json), content_type="application/json")
		except ObjectDoesNotExist as e:
			print 'object does not exist'
			# Register device.
			if system == 'iOS':
				device = APNSDevice.objects.create(registration_id=device_token)
			else:
				device = GCMDevice.objects.create(registration_id=device_token)
			# This device is successfully registered.
			print 'create object in db: %s' % (device)
			response_json['message'] = 'This device is successfully registered.'
			return HttpResponse(json.dumps(response_json), content_type="application/json")
	else:
		response_json['message'] = 'Bad Request: The server only supports POSTs.'
		return HttpResponseBadRequest(json.dumps(response_json), content_type="application/json")


# Handler for our callback endpoint (subscriber_url) we registered with AS.
# TODO: 
# 2. add the field to new_request response to specify the device
# to hit the server, type into terminal:
# curl -X POST -H "Content-Type: application/json"   -d '{"device_id":"APA91bEKvxn-y2oGlUDvGEZw9cpDCHYS0AukuelvEd2taXEMpZ7rMKJQfiYPK_viwuI19kCTOkj3JKBQBPFjb6w4WDeD1696U_G7picM0yKZ027a3tuVeyZ7_LdVAqrUe0GiRGv25sNpZe5DplbC5yRYAK9LL3_KeA", "system":"Android", "seat_id":"NameOfSeat", "reservation_result":"available"}' http://serene-wave-9290.herokuapp.com/reservation_result/
@csrf_exempt
def reservation_result(request):
	response_json = {}
	print 'in_reservation_result'
	
	if request.method == "POST":
		print 'in request.method POST'
		device_json = json.loads(request.body)
		print 'load json'
		device_id = device_json["device_id"]
		system = device_json['system']
		seat = device_json['seat_id']
		result = device_json['reservation_result']

		print '====device info====='
		print device_id
		print system
		print seat
		print result
		print '====device info end====='

		# TODO: error result: error code or status
		if device_id == "":
			print 'device id is not specified'
			# Didn't get device token
			response_json['message'] = 'The server did not specify device id'
			return HttpResponse(json.dumps(response_json), content_type="application/json")

		try:
			print 'try to match device in db'
			# This device is already registered.
			if system == 'iOS':
				device = APNSDevice.objects.get(registration_id=device_id)

				# Alert message may only be sent as text.
				device.send_message("The seat reservation for " + seat + " is " + result)
				device.send_message(None, badge=5) # No alerts but with badge.
				device.send_message(None, badge=1, extra={"foo": "bar"}) # Silent message with badge and added custom data.
			else:
				device = GCMDevice.objects.get(registration_id=device_id)
				# The first argument will be sent as "message" to the intent extras Bundle
				# Retrieve it with intent.getExtras().getString("message")
				# Alert message may only be sent as text.
				device.send_message("The seat reservation for " + seat + " is " + result)

				# If you want to customize, send an extra dict and a None message.
				# the extras dict will be mapped into the intent extras Bundle.
				# For dicts where all values are keys this will be sent as url parameters,
				# but for more complex nested collections the extras dict will be sent via
				# the bulk message api.
				device.send_message(None, extra={"foo": "bar"})
			
			print 'successfully sent push notification'
			response_json['message'] = 'The server successfully sent push notification to devices.'
			return HttpResponse(json.dumps(response_json), content_type="application/json")
		
		# TODO: error result: error code or status
		except (GCMDevice.DoesNotExist, APNSDevice.DoesNotExist) as e:
			print 'device not found'
			response_json['message'] = 'This device is not registered.'
			return HttpResponse(json.dumps(response_json), content_type="application/json")
	else:
		response_json['message'] = 'Bad Request: The server only supports POSTs.'
		return HttpResponseBadRequest(json.dumps(response_json), content_type="application/json")


# this function is used by the server to subscribe itself (subscriber_id) with AS. It registers a callback that points to itself at /reservation_result. AS will POST any activity notifications to this endpoint for this subscriber (once we subscribe for them elsewhere).
def create_phone_notifications_subscriber(request):
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

# Endpoint used by the server/admin to subscribe the *server* (hard-coded id subscription_id_deny right now) with ASBase. Should only need to be done once for this service!
def create_deny_reservation_subscription(request):
	# create_subscription_by_verb(response, 'deny', subscription_id_deny)
	verb = 'deny'
	subscription_id = subscription_id_deny

        # in case someone tries accessing this endpoint again after a prior subscription, we check our subscriber_id to see if we're already subscribed first.
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

# Endpoint used by the server/admin to subscribe the *server* (hard-coded id subscription_id_approve right now) with ASBase. Should only need to be done once for this service!
def create_approve_reservation_subscription(request):
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
