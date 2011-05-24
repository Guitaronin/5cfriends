$(document).ready(function() {

	$('input.bkg_top_search_input').focus(function() {
		if (this.value == 'Phone Number') {
			this.value = '';
		}
	});
	
	$('input.bkg_top_search_input').blur(function() {
		if (this.value == '') {
			this.value = 'Phone Number';
		}
	});
	
	$('input.bkg_home_search_input').focus(function() {
		if (this.value == 'Phone Number') {
			this.value = '';
		}
	});
	
	$('input.bkg_home_search_input').blur(function() {
		if (this.value == '') {
			this.value = 'Phone Number';
		}
	});
	
});