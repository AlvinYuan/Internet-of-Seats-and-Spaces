from django.shortcuts import render
from datetime import datetime
from django.contrib.sites.models import Site
from django.http import HttpResponseBadRequest
import json
import requests

ASBase_url = "http://russet.ischool.berkeley.edu:8080"

subscriber_id = "ISchool Seating Reservation System"
subscriber_url = Site.objects.all()[0].domain + "/new_request"

# Create your views here.
def new_request(response):
	if response.method == "POST":
		activity_json = json.loads(request.body)
		print str(activity_json)
		# Reject activity if it is not a request
		if activity_json["verb"] != "request":
			return HttpResponseBadRequest("<h1>Bad Request</h1><p>Input was not a request activity.</p>")

		# Reject activity if it is not under our management
		# TODO: how to generalize this?
		# Maybe all objects need to include South Hall in name?
		if activity_json["object"]["displayName"] != "Chair at 202 South Hall, UC Berkeley":
			return HttpResponseBadRequest("<h1>Bad Request</h1><p>Requested object is not managed by us.</p>")

		activity_response = {}
		activity_response["actor"] = self_object = {"displayName": subscriber_id, "id": subscriber_url}
		activity_response["verb"] = "deny"
		activity_response["reason"] = "Your request has been noted, but these seats are not reservable."
		activity_response["object"] = activity_json
		activity_response["published"] = datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ")
		# post activity_response asJson to russet.ischool.berkeley.edu:8080
	else:
		# WORKING HERE.
		# Test with get requests. Try posting to ASBase using requests library
		activity_response = {}
		activity_response["actor"] = self_object = {"displayName": subscriber_id, "id": subscriber_url}
		activity_response["verb"] = "deny"
		activity_response["reason"] = "Your request has been noted, but these seats are not reservable."
		activity_response["object"] = None
		activity_response["published"] = datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ")
		print json.dumps(activity_response)
		headers = {'Content-Type': 'application/stream+json'}
		r = requests.post("/activities/", data=json.dumps(activity_response), headers=headers)
		print r.content
		return HttpResponseBadRequest("<h1>Bad Request</h1><p>The server only supports POSTs.</p>")

def create_subscriber(response):
	subscribe_url = ASBase_url + "/users"
	r = requests.get(subscribe_url)
	users = r.json()
	if subscriber_id in users["userIDs"]:
		return HttpResponse("\""subscriber_id + "\" is already subscribed to " = ASBase_url)
	else:
		subscriber = {}
		subscriber["subscriberID"] = subscriber_id
		subscriber["channel"] = {"type": "URL_callback", "data": subscriber_url}

		headers = {'Content-Type': 'application/json'}
		r = requests.post (subscribe_url, data=json.dumps(subscriber), headers=headers)
		return HttpResponse(r.content)
