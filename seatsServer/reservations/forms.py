from django import forms

class ChairUpdateForm(forms.Form):
	actor_displayName = forms.CharField(initial="Unknown")
	verb = forms.ChoiceField(choices=[("checkin","checkin"), ("leave", "leave")])
	object_displayName = forms.CharField(initial="Chair at 202 South Hall, UC Berkeley")
	object_id = forms.CharField(initial="http://example.org/berkeley/southhall/202/chair/1")
	object_descriptor_tags = forms.CharField(initial="chair, rolling", help_text="Comma separated")
