/*global Vue, _ */

(function(exports) {
	'use strict';

	moment.locale('de');

	Vue.component('logentry', {
		template: '#template-logentry-raw',
		props: [
			'logentry',
			'categories',
			'categorygroups'
		],
		methods: {
			deletelogentry: function(logentry) {
				var that = this;
				alertify.confirm('Löschen?', 'Diesen Eintrag wirklich löschen?',
						function() {
								var index = that.$parent.logentries.indexOf(logentry);
								that.$parent.logentries.splice(index, 1);
								that.$http.delete('/logentry/' + logentry.entry_id);
								alertify.success('Eintrag gelöscht');
						},
						function() {
							logentry.editing = false;
						}
					);
			},
			editlogentry: function(logentry) {
				logentry.editing = true;
			},
			createlogentry: function(logentry) {
				this.$http.post('logentry', logentry).then(function (response) {
					/*
						After the the new logentry is stored in the database fetch again all logentries with
						vm.fetchlogentries();
						Or Better, update the id of the created logentry
					*/
					Vue.set(logentry, 'entry_id', response.data.entry_id);

					//Set editing to false to show actions again and hide the inputs
					logentry.editing = false;
				});
			},
			updatelogentry: function(logentry) {
				this.$http.put('/logentry/' + logentry.entry_id, logentry);
				// Set editing to false to show actions again and hide the inputs
				logentry.editing = false;
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
			}
		},
		filters: {
			formatDateShort: function(value) {
				return (value ? moment(value).format("DD. MMMM YYYY") : '');
			},
			formatTimeShort: function(value) {
				return (value ? moment(value).format("HH:mm") : '');
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
						logentry.categories = logentry.categories || [];
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
						categories: [],
						editing: true
					});
			}
		},
		computed: {
			categorygroups: function() {
				return _.groupBy(_.sortBy(this.categories, 'title'), 'cgroup');
			}
		},
	});
})(window);
