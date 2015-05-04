from django.shortcuts import render_to_response, render, redirect
from datetime import datetime
from django.contrib.sites.models import Site
from django.http import HttpResponseBadRequest, HttpResponse
from django.views.decorators.csrf import csrf_exempt
from .forms import ChairUpdateForm
import json
import requests
import urllib

ASBase_url = "http://russet.ischool.berkeley.edu:8080"

provider = {"displayName":"BerkeleyChair"}
subscriber_id = "ISchool Seating Reservation System"
subscriber_url = "http://" + Site.objects.all()[0].domain + "/new_request/"
subscription_id = "South Hall Requests"
subscription_actor_text = "South Hall"

# Create your views here.
@csrf_exempt
def new_request(request):
	if request.method == "POST":
		activity_json = json.loads(request.body)
		print json.dumps(activity_json)
		# Reject activity if it is not a request
		if activity_json["verb"] != "request":
			return HttpResponseBadRequest("<h1>Bad Request</h1><p>Input was not a request activity.</p>")

		# Reject activity if it is not under our management
		if subscription_actor_text not in activity_json["object"]["displayName"]:
			return HttpResponseBadRequest("<h1>Bad Request</h1><p>Requested object is not managed by us.</p>")

		activity_response = {}
		activity_response["actor"] = {"displayName": subscriber_id, "id": subscriber_url}
		activity_response["verb"] = "deny"
		activity_response["reason"] = "Your request has been noted, but these seats are not reservable."
		activity_response["object"] = activity_json
		activity_response["published"] = datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ")
		activity_response["provider"] = provider

		headers = {'Content-Type': 'application/stream+json'}
		r = requests.post(ASBase_url + "/activities/", data=json.dumps(activity_response), headers=headers)
		print r.content
		return HttpResponse(r.content)
	else:
		return HttpResponseBadRequest("<h1>Bad Request</h1><p>The server only supports POSTs.</p>")

def create_subscriber(request):
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

def create_reservation_subscription(request):
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
		subscription["ASTemplate"]["verb"] = { "$in": ["request"] }

		headers = {'Content-Type': 'application/json'}
		r = requests.post (subscription_url, data=json.dumps(subscription), headers=headers)
		return HttpResponse(r.content)

def documentation(request):
	return render_to_response('documentation.html', {})

# For simulation/testing
def post_chair_update(request):
	if request.method == "GET":
		return render(request, "post_chair_update.html", {"form": ChairUpdateForm() })
	else:
		form = ChairUpdateForm(request.POST)
		if form.is_valid():
			activity = {}
			activity["actor"] = {"displayName": form.cleaned_data["actor_displayName"], "objectType": "person"}
			activity["verb"] = form.cleaned_data["verb"]
			activity["object"] = {
			"displayName": form.cleaned_data["object_displayName"],
			"id": form.cleaned_data["object_id"],
			"objectType": "place",
			"descriptor-tags": form.cleaned_data["object_descriptor_tags"].split(","),
			"address": {
				"locality": "Berkeley",
				"region": "CA",
				}
			}
			activity["published"] = datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ")
			activity["provider"] = provider

			headers = {'Content-Type': 'application/stream+json'}
			r = requests.post(ASBase_url + "/activities/", data=json.dumps(activity), headers=headers)
			print r.content
			return HttpResponse(r.content)
		else:
			return render(request, "post_chair_update.html", {"form": form})

def request_administrator_view(request):
	query_url = ASBase_url + "/query"
	if request.method == 'GET':
		requests_query_template = {
			"verb": {"$in": ["request"]},
			"provider.displayName": {"$in": [provider["displayName"]]}
		}
		requests_status_query_template = {
			"verb": {"$in": ["cancel", "approve", "deny"]},
			"object.verb": {"$in": ["request"]},
			"object.provider.displayName": {"$in": [provider["displayName"]]}
		}

		headers = {'Content-Type': 'application/json'}
		r = requests.post(query_url, data=json.dumps(requests_query_template), headers=headers)
		request_activities = r.json()["items"]
		r = requests.post(query_url, data=json.dumps(requests_status_query_template), headers=headers)
		request_status_activities = r.json()["items"]
		request_status_map = {}
		request_map = {}
		for rs in request_status_activities:
			request_status_map[rs["object"]["id"]] = rs
		for r in request_activities:
			request_map[r["id"]] = r
			if r["id"] in request_status_map:
				request_map[r["id"]]["status"] = request_status_map[r["id"]]["verb"]
				if request_status_map[r["id"]]["verb"] == "deny":
					request_map[r["id"]]["reason"] = request_status_map[r["id"]]["reason"]
			else:
				request_map[r["id"]]["status"] = "open"

		request_list = request_map.values()
		# TODO: sort in a more meaningful way? Something related to time.
		request_list = sorted(request_list, key=lambda ra: ra["status"])
		return render(request, 'request_administrator_view.html', {"requests": request_list})
	else:
		pass

def handle_request(request, verb):
	query_url = ASBase_url + "/query"
	request_id = urllib.unquote(request.GET.get("request_id", ""))
	print request_id
	request_template = {
		"verb": {"$in": ["request"]},
		"id": {"$in": [request_id]}
	}

	headers = {'Content-Type': 'application/json'}
	r = requests.post(query_url, data=json.dumps(request_template), headers=headers)
	request_activity = r.json()["items"]

	if request_activity:
		request_activity = request_activity[0]
		activity_response = {}
		activity_response["actor"] = {"team": "IoSeats", "displayName": "Administrator"}
		activity_response["verb"] = verb
		if "reason" in request.GET:
			activity_response["reason"] = request.GET.get("reason")
		activity_response["object"] = request_activity
		activity_response["published"] = datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ")
		activity_response["provider"] = provider

		headers = {'Content-Type': 'application/stream+json'}
		r = requests.post(ASBase_url + "/activities/", data=json.dumps(activity_response), headers=headers)
		return redirect('request_administrator_view')

	else:
		return HttpResponseBadRequest("<h1>Bad Request</h1><p>Request id not found.</p>")
