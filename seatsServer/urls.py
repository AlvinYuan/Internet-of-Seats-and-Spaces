from django.conf.urls import patterns, include, url
from django.contrib import admin
import reservations.views
import phoneNotifications.views

urlpatterns = patterns('',
    # Examples:
    # url(r'^$', 'seatsServer.views.home', name='home'),
    # url(r'^blog/', include('blog.urls')),

    url(r'^admin/', include(admin.site.urls)),
    url(r'^new_request/', reservations.views.new_request, name='new_request'),
    url(r'^create_subscriber/', reservations.views.create_subscriber, name='create_subscriber'),
    url(r'^create_reservation_subscription/', reservations.views.create_reservation_subscription, name='create_reservation_subscription'),

    url(r'^register_device/', phoneNotifications.register_device.reservation_result, name='register_device'),
    url(r'^reservation_result/', phoneNotifications.views.reservation_result, name='reservation_result'),
    url(r'^create_phone_notifications_subscriber/', phoneNotifications.views.create_phone_notifications_subscriber, name='create_phone_notifications_subscriber'),
    url(r'^create_deny_reservation_subscription/', phoneNotifications.views.create_deny_reservation_subscription, name='create_deny_reservation_subscription'),
    url(r'^create_approve_reservation_subscription/', phoneNotifications.views.create_approve_reservation_subscription, name='create_approve_reservation_subscription'),   
)
