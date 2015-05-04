from django.conf.urls import patterns, include, url
from django.contrib import admin
import reservations.views
import phoneNotifications.views
import bartChairs.views
import phoneRealTimeUpdates.views

urlpatterns = patterns('',
    # Examples:
    # url(r'^$', 'seatsServer.views.home', name='home'),
    # url(r'^blog/', include('blog.urls')),

    # Admin
    url(r'^admin/', include(admin.site.urls)),
    # Documentation
    url(r'^schema-documentation/', reservations.views.documentation, name='documentation'),
    # Reservations
    url(r'^new_request/', reservations.views.new_request, name='new_request'),
    url(r'^create_subscriber/', reservations.views.create_subscriber, name='create_subscriber'),
    url(r'^create_reservation_subscription/', reservations.views.create_reservation_subscription, name='create_reservation_subscription'),
    url(r'^request_administrator_view/', reservations.views.request_administrator_view, name='request_administrator_view'),
    url(r'^request/(?P<verb>approve|deny)/', reservations.views.handle_request, name='handle_request'),
    # Simulate Chair
    url(r'^post_chair_update/', reservations.views.post_chair_update, name='post_chair_update'),

    # Reservations BART
    url(r'^new_request_bart/', bartChairs.views.new_request_bart, name='new_request_bart'),
    url(r'^create_subscriber_bart/', bartChairs.views.create_subscriber_bart, name='create_subscriber_bart'),
    # subscribe to train record:
    url(r'^create_reservation_subscription_bart/', bartChairs.views.create_reservation_subscription_bart, name='create_reservation_subscription_bart'),
    
    # Phone Notifications
    url(r'^register_device/', phoneNotifications.views.register_device, name='register_device'),
    url(r'^reservation_result/', phoneNotifications.views.reservation_result, name='reservation_result'),
    url(r'^create_phone_notifications_subscriber/', phoneNotifications.views.create_phone_notifications_subscriber, name='create_phone_notifications_subscriber'),
    url(r'^create_deny_reservation_subscription/', phoneNotifications.views.create_deny_reservation_subscription, name='create_deny_reservation_subscription'),
    url(r'^create_approve_reservation_subscription/', phoneNotifications.views.create_approve_reservation_subscription, name='create_approve_reservation_subscription'),

    # Phone Real Time Updates
    url(r'^phoneRealTimeUpdates/place_status_update/', phoneRealTimeUpdates.views.place_status_update),
    url(r'^phoneRealTimeUpdates/create_subscriber/', phoneRealTimeUpdates.views.create_subscriber),
    url(r'^phoneRealTimeUpdates/create_normal_update_subscription/', phoneRealTimeUpdates.views.create_normal_update_subscription),
    url(r'^phoneRealTimeUpdates/create_reservation_update_subscription/', phoneRealTimeUpdates.views.create_reservation_update_subscription),
)
