/*global Vue, _, axios */

(function(exports) {
	'use strict';

	moment.locale('de');

	Vue.component('datetime-input', {
		template: '#template-datetime-input',
		props: ['value'],
		methods: {
			updateValue: function(valTarget, newValue) {
				var formattedValue;

				switch (valTarget) {
					case 'date':
						formattedValue = newValue + this.value.substr(this.value.indexOf(' '));
						break;
					case 'time':
						formattedValue = this.value.substr(0, this.value.indexOf(' ') + 1) + newValue;
						break;
				}

				this.$emit('input', formattedValue);
			}
		},
		computed: {
			cdate: function() {
				return moment(this.value).format("YYYY-MM-DD");
			},
			ctime: function() {
				return moment(this.value).format("HH:mm");
			}
		}
	});

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
								that.$http.delete('logentry/' + logentry.entry_id);
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
				axios.post('logentry', logentry).then(function (response) {
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
				axios.put('logentry/' + logentry.entry_id, logentry);
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
			},
			addToFilter: function(category_id) {
				var filterStr = 'cat:' + this.getCategory(category_id).title;

				if (this.$parent.searchValue.length > 0) {
					this.$parent.searchValue += ' ' + filterStr;
				}
				else {
					this.$parent.searchValue = filterStr;
				}

				this.$parent.fetchlogentries();
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
			infotext: undefined,
			errortext: undefined,
			categories: {},
			pagination: {},
			logentries: [],
			searchValue: ''
		},
		watch: {
			infotext: function (val) {
				if (_.isArray(val)) {
					_.each(val, function(message) {
							alertify.notify(message);
						});
				}
				else {
					alertify.notify(val);
				}
			},
			errortext: function(val) {
				if (_.isArray(val)) {
					_.each(val, function(message) {
							alertify.error(message);
						});
				}
				else {
					alertify.error(val);
				}
			}
		},
		mounted: function() {
			this.fetchCategories();
			this.fetchlogentries();
		},
		methods: {
			fetchCategories: function() {
				var vm = this;
				axios.get('categories').then(function(response) {
					Vue.set(vm, 'categories', response.data);
				});
			},
			fetchlogentries: function(url_date) {
				var vm = this,
						urlParameters = [];

				if (url_date) {
					urlParameters.push('t=' + encodeURIComponent(url_date));
				}
				else if (this.pagination && this.pagination.cur_month) {
					urlParameters.push('t=' + encodeURIComponent(this.pagination.cur_month));
				}

				if (this.searchValue.length) {
					urlParameters.push('q=' + encodeURIComponent(this.searchValue));
				}

				axios.get('logentries?' + urlParameters.join('&')).then(function (response) {
					var logentriesReady = response.data.data.map(function(logentry) {
						logentry.editing = false;
						logentry.categories = logentry.categories || [];
						return logentry;
					});

					// Poplulate logentries-data in Application
					Vue.set(vm, 'logentries', logentriesReady);
					Vue.set(vm, 'pagination', response.data.pagination);
					Vue.set(vm, 'infotext', response.data.infotext);
					Vue.set(vm, 'errortext', response.data.errortext);
				});
			},
			createlogentry: function(predefAttrs) {
				var tmpObj = {
						edate: moment().format('YYYY-MM-DD HH:mm:ss'),
						author: (document.getElementById('rusername') ? document.getElementById('rusername').value : ''),
						title: '',
						description: '',
						categories: [],
						editing: true
					};

				if (predefAttrs) {
					_.extend(tmpObj, predefAttrs);
				}

				// Insert Entry at the beginning
				this.logentries.unshift(tmpObj);
			},
			clearSearchinput: function() {
				this.searchValue = '';
				this.fetchlogentries();
			}
		},
		computed: {
			categorygroups: function() {
				return _.groupBy(_.sortBy(this.categories, 'title'), 'cgroup');
			}
		},
		filters: {
			formatMonthPage: function(value) {
				return (value ? moment(value).format("MMMM YYYY") : '');
			},
		}
	});
})(window);
