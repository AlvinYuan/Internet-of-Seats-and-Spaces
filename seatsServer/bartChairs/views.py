from django.shortcuts import render_to_response, render, redirect
from datetime import datetime
from django.contrib.sites.models import Site
from django.http import HttpResponseBadRequest, HttpResponse
from django.views.decorators.csrf import csrf_exempt
import json
import requests
import urllib

ASBase_url = "http://russet.ischool.berkeley.edu:8080"

provider = {"displayName":"BerkeleyChair"}
subscriber_id = "BART Seating Reservation System"
subscriber_url = "http://" + Site.objects.all()[0].domain + "/new_request_bart/"
subscription_id = "BART Requests"
subscription_actor_text = "BART"

# Create your views here.
@csrf_exempt
def new_request_bart(request):
	if request.method == "POST":
		activity_json = json.loads(request.body)
		print json.dumps(activity_json)

		activity_response = activity_json
		activity_response["object"]["objectType"] = "trainRecordWithSeatingInfo"

		activity_response["object"]["dataFields"]["car_1"]["availableSeats"] = 5

		headers = {'Content-Type': 'application/stream+json'}
		r = requests.post(ASBase_url + "/activities/", data=json.dumps(activity_response), headers=headers)
		print r.content
		return HttpResponse(r.content)
	else:
		return HttpResponseBadRequest("<h1>Bad Request</h1><p>The server only supports POSTs.</p>")

def create_subscriber_bart(request):
	print "create subscriber"
	subscribe_url = ASBase_url + "/users"
	r = requests.get(subscribe_url)
	users = r.json()
	if subscriber_id in users["userIDs"]:
		# Code to clean up stale subscribers
		# r = requests.delete (subscribe_url + "/" + subscriber_id)
		# print r.content
		return HttpResponse('"' + subscriber_id + '" is already subscribed to ' + ASBase_url)
	else:
		subscriber = {}
		subscriber["userID"] = subscriber_id
		subscriber["channels"] = [{"type": "URL_Callback", "data": subscriber_url}]

		print json.dumps(subscriber)
		headers = {'Content-Type': 'application/json'}
		r = requests.post (subscribe_url, data=json.dumps(subscriber), headers=headers)
		return HttpResponse(r.content)

def create_reservation_subscription_bart(request):
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
		subscription["userID"] = subscriber_id #specify this
		subscription["subscriptionID"] = subscription_id
		subscription["ASTemplate"] = {}
		subscription["ASTemplate"]["object.objectType"] = { "$in":["trainRecord"]}
		subscription["ASTemplate"]["verb"] = { "$in": ["checkin"] }

		headers = {'Content-Type': 'application/json'}
		r = requests.post (subscription_url, data=json.dumps(subscription), headers=headers)
		return HttpResponse(r.content)
