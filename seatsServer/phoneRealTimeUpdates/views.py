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

subscriber_id = "Real Time Place Status Updates"
subscriber_url = "http://" + Site.objects.all()[0].domain + "/phoneRealTimeUpdates/place_status_update/"
normal_update_verbs = ["checkin", "leave", "request"]
reservation_update_verbs = ["cancel", "approve", "deny"]

# See phoneNotifications.views.register_device for device registration.

@csrf_exempt
def place_status_update(request):
	response_json = {}
	if request.method == "POST":
		activity_json = json.loads(request.body)

		# TODO: check for errors in input activity_json

		# Might be a lot of spam in real world situations?
		# We can expose a server url to allow phones to mark themselves as non-active (when the close they app.)
		ios_devices = APNSDevice.objects.filter(active=True)
		android_devices = GCMDevice.objects.filter(active=True)

		# Currently just forwards activity to the phone and has phone deal with updating logic.
		# Can instead send a custom message and have some logic on the server to reduce payload size and phone logic.
		ios_devices.send_message("Place Status Update")
		ios_devices.send_message(None, badge=1, extra=activity_json)
		android_devices.send_message("Place Status Update")
		android_devices.send_message(None, extra=activity_json)

		response_json['message'] = 'The server sent push notification to ' + str(len(ios_devices) + len(android_devices)) + ' devices.'
		return HttpResponse(json.dumps(response_json), content_type="application/json")
	else:
		response_json['message'] = 'Bad Request: The server only supports POSTs.'
		return HttpResponseBadRequest(json.dumps(response_json), content_type="application/json")

def create_subscriber(request):
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

def create_normal_update_subscription(request):
	subscription_id = ", ".join(normal_update_verbs)

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
		subscription["ASTemplate"]["verb"] = { "$in": normal_update_verbs }
		subscription["ASTemplate"]["object.objectType"] = { "$in": ["place"] }
		subscription["ASTemplate"]["provider.displayName"] = { "$in": ["BerkeleyChair"] }

		headers = {'Content-Type': 'application/json'}
		r = requests.post (subscription_url, data=json.dumps(subscription), headers=headers)
		return HttpResponse(r.content)

def create_reservation_update_subscription(request):
	subscription_id = ", ".join(reservation_update_verbs)

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
		subscription["ASTemplate"]["verb"] = { "$in": reservation_update_verbs }
		subscription["ASTemplate"]["object.verb"] = { "$in": ["request"] }
		subscription["ASTemplate"]["object.object.objectType"] = { "$in": ["place"] }
		subscription["ASTemplate"]["provider.displayName"] = { "$in": ["BerkeleyChair"] }

		headers = {'Content-Type': 'application/json'}
		r = requests.post (subscription_url, data=json.dumps(subscription), headers=headers)
		return HttpResponse(r.content)