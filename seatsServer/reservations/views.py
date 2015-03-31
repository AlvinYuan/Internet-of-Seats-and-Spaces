from django.shortcuts import render
from datetime import datetime
from django.contrib.sites.models import Site
from django.http import HttpResponseBadRequest
import json

self_object = {}
self_object["displayName"] = "ISchool Seating Reservation System"
self_object["id"] = Site.objects.all()[0].domain

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
		activity_response["actor"] = self_object
		activity_response["verb"] = "deny"
		activity_response["reason"] = "Your request has been noted, but these seats are not reservable."
		activity_response["object"] = activity_json
		activity_response["published"] = datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ")
		# post activity_response asJson to russet.ischool.berkeley.edu:8080
	else:
		# WORKING HERE.
		# Test with get requests. Try posting to ASBase using requests library
		activity_response = {}
		activity_response["actor"] = self_object
		activity_response["verb"] = "deny"
		activity_response["reason"] = "Your request has been noted, but these seats are not reservable."
		activity_response["object"] = None
		activity_response["published"] = datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ")
		print json.dumps(activity_response)
		return HttpResponseBadRequest("<h1>Bad Request</h1><p>The server only supports POSTs.</p>")


