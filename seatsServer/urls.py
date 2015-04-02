from django.conf.urls import patterns, include, url
from django.contrib import admin
import reservations.views

urlpatterns = patterns('',
    # Examples:
    # url(r'^$', 'seatsServer.views.home', name='home'),
    # url(r'^blog/', include('blog.urls')),

    url(r'^admin/', include(admin.site.urls)),
    url(r'^new_request/', reservations.views.new_request, name='new_request'),
    url(r'^create_subscriber/', reservations.views.create_subscriber, name='create_subscriber'),
    url(r'^create_reservation_subscription/', reservations.views.create_reservation_subscription, name='create_reservation_subscription'),
)
