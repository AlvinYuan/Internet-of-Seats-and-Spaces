from django.shortcuts import render
from datetime import datetime
from django.contrib.sites.models import Site
from django.http import HttpResponseBadRequest, HttpResponse
from django.views.decorators.csrf import csrf_exempt
import json
import requests

ASBase_url = "http://russet.ischool.berkeley.edu:8080"

subscriber_id = "Seating Reservation Result Notification System"
subscriber_url = "http://" + Site.objects.all()[0].domain + "/reserversion_result/"
# subscriber_url = "http://serene-wave-9290.herokuapp.com/reserversion_result/"
subscription_id_deny = "DeniedReservationSubscription"
subscription_id_approve = "ApprovedReservationSubscription"
subscription_actor_text = "Reserversion Result"

# @csrf_exempt
# def register_device(response):
	# print "blah"
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
		r = requests.delete (subscribe_url + "/" + subscriber_id)
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
