Per Alvin,
* In seatsServer, there should be a requirements.txt. This specifies all the dependencies that you need to run the server. You can install these by typing the following into the terminal: `pip install -r requirements.txt`. Best practice usually involves using `virtualenv` first. See e.g. <http://www.dabapps.com/blog/introduction-to-pip-and-virtualenv-python/>
* In seatsServer, there should be a manage.py. You can use this to start a local server via `python manage.py runserver`. A local server is nice for testing b/c you can see print statements in your code pretty easily (you can do this with heroku too, just have to run some other command).
* When you run locally, comment out this line from `seatsServer/seatsServer/settings.py`: `DATABASES['default'] =  dj_database_url.config()`. When you push to heroku, leave it uncommented.
* You update the heroku server via pushing with git. To do this, first you need to add the heroku server as a remote repo: `git remote add heroku  git@heroku.com:serene-wave-9290.git`
* Now you can push to heroku via `git subtree push --prefix seatsServer heroku master`. This is not the normal git push, because you have to push just the Django code (seatsServer).
* `seatsServer/seatsServer/urls.py` connects urls to methods that you wrote, so that when the url is visited, your method handles it.
* `seatsServer/reservations/views.py` holds the methods for reservation-related urls. In it you can see one to create a subscriber, one to create a subscription, and one to handle updates.

You can also send test push notifications via the `/admin` panel. You'll need to be a useruser to access it. For local servers, you can create one with `python manage.py createsuperuser.py`.
