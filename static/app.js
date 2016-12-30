/*global Vue */

(function(exports) {
	'use strict';

	moment.locale('de');

	Vue.component('logentry', {
		template: '#template-logentry-raw',
		props: ['logentry', 'categories'],
		methods: {
			deletelogentry: function(logentry) {
				var index = this.$parent.logentries.indexOf(logentry);
				this.$parent.logentries.splice(index, 1);
				this.$http.delete('/logentry/' + logentry.id);
			},
			editlogentry: function(logentry) {
				logentry.editing = true;
			},
			updatelogentry: function(logentry) {
				this.$http.patch('/logentry/' + logentry.id, logentry);
				// Set editing to false to show actions again and hide the inputs
				logentry.editing = false;
			},
			storelogentry: function(logentry) {
				this.$http.post('logentry', logentry).then(function (response) {
					/*
						After the the new logentry is stored in the database fetch again all logentries with
						vm.fetchlogentries();
						Or Better, update the id of the created logentry
					*/
					Vue.set(logentry, 'entry_id', response.data.id);

					//Set editing to false to show actions again and hide the inputs
					logentry.editing = false;
				});
			},
			cancelEditNewlogentry: function(logentry) {
				if (logentry.entry_id) {
					logentry.editing = false;
				}
				else {
					var index = this.$parent.logentries.indexOf(logentry);
					this.$parent.logentries.splice(index, 1);
				}
			},
			getCategory: function(category_id) {
				return this.categories[ category_id ];
			},
			toggleCategory: function(logentry, category) {
				var tmpCategories = logentry.categories;
				if (tmpCategories[category.category_id]) {
					delete tmpCategories[category.category_id];
				}
				else {
					tmpCategories[category.category_id] = 1;
				}
				debugger;
				this.$set(this.logentry, 'categories', tmpCategories);
			}
		},
		filters: {
			formatDatetimeShort: function(value) {
				return (value ? moment(value).format("DD. MMM YY") : '');
			},
			formatDatetimeFull: function(value) {
				return (value ? moment(value).format("dddd, DD.MM.YYYY, HH:mm") : '');
			}
		}
	});

	exports.app = new Vue({
		el: '#v-app',
		data: {
			categories: {},
			pagination: {},
			logentries: []
		},
		mounted: function() {
			this.fetchCategories();
			this.fetchlogentries();
		},
		methods: {
			fetchCategories: function() {
				var vm = this;
				this.$http.get('categories').then(function(response) {
					Vue.set(vm, 'categories', response.data);
				});
			},
			fetchlogentries: function() {
				var vm = this;
				this.$http.get('logentries').then(function (response) {
					var logentriesReady = response.data.data.map(function(logentry) {
						logentry.editing = false;
						return logentry;
					});

					// Poplulate logentries-data in Application
					Vue.set(vm, 'logentries', logentriesReady);
					Vue.set(vm, 'pagination', response.data.pagination);
				});
			},
			createlogentry: function() {
				// Insert Entry at the beginning
				this.logentries.unshift({
						edate: moment().format('YYYY-MM-DD HH:mm:ss'),
						title: '',
						description: '',
						author: '',
						categories: {},
						editing: true
					});
			}
		}
	});
})(window);
