import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations._();

  static final Map<String, Map<String, String>> _translations = {
    'en': {
      'app.title': 'Time Tracker',
      'nav.log': 'Log',
      'nav.map': 'Map',
      'nav.stats': 'Statistics',
      'home.header.subtitle': 'Time Tracker',
      'home.settings.title': 'Settings',
      'home.settings.language': 'Language',
      'home.settings.language.es': 'Spanish',
      'home.settings.language.en': 'English',
      'home.settings.export': 'Export Data',
      'home.settings.export.subtitle': 'Export every activity as JSON',
      'home.settings.import': 'Import Data',
      'home.settings.import.subtitle': 'Import activities from JSON file',
      'home.settings.backups': 'Automatic Backups',
      'home.settings.backups.subtitle': 'View and restore local backups',
      'home.settings.about': 'About',
      'home.settings.about.subtitle':
          'Time Tracker is an elegant app to record and visualise activities over time.',
      'home.settings.delete': 'Delete all data',
      'home.settings.delete.subtitle': 'This action cannot be undone',
      'home.settings.close': 'Close',
      'home.dialog.export.success': 'Done! Data exported successfully',
      'home.dialog.export.error': 'There was a problem exporting the data',
      'home.dialog.import.title': 'Confirm Import',
      'home.dialog.import.message':
          'Do you want to import {count} activities?\n\nExisting activities will remain.',
      'home.dialog.import.success':
          'Done! {count} activities imported successfully',
      'home.dialog.import.error': 'There was a problem importing the data',
      'home.dialog.backup.empty': 'No backups available',
      'home.dialog.backup.date': '{size} • {date}',
      'home.dialog.backup.restore.success':
          'Done! Backup restored successfully',
      'home.dialog.backup.restore.error':
          'There was a problem restoring the backup',
      'home.dialog.backup.create.success': 'Done! Backup created successfully',
      'home.dialog.backup.create.error': 'The backup could not be created',
      'home.dialog.backup.create': 'Create Backup',
      'home.dialog.cancel': 'Cancel',
      'home.dialog.confirm': 'Confirm',
      'home.dialog.delete.title': '⚠️ Confirm deletion',
      'home.dialog.delete.message':
          'Are you sure you want to delete ALL data? This action cannot be undone and you will lose every logged activity.',
      'home.dialog.delete.success': 'All data has been deleted',
      'activities.header': 'Activity Log',
      'activities.search.hint': 'Search activity...',
      'activities.filter.category': 'Category',
      'activities.filter.provider': 'Provider',
      'activities.filter.country': 'Country',
      'activities.filter.allCategories': 'All categories',
      'activities.filter.allProviders': 'All providers',
      'activities.filter.allCountries': 'All countries',
      'activities.filter.toggle': 'Adjust filters',
      'activities.empty.title': 'No activities registered yet',
      'activities.empty.subtitle': 'Tap the + button to add your first entry',
      'activities.menu.edit': 'Edit',
      'activities.menu.delete': 'Delete',
      'activities.dialog.delete.title': 'Confirm deletion',
      'activities.dialog.delete.message':
          'Are you sure you want to delete "{name}"?',
      'activities.dialog.delete.confirm': 'Delete',
      'activities.dialog.delete.cancel': 'Cancel',
      'activities.notes': 'Notes',
      'activities.noNotes': 'No notes',
      'activities.timeSince.moment': 'a moment ago',
      'activities.timeSince.minutes': '{minutes} minutes ago',
      'activities.timeSince.hours': '{hours} hours ago',
      'activities.timeSince.days': '{days} days ago',
      'activities.interval.average': 'Avg: {duration}',
      'activities.interval.last': 'Last: {duration}',
      'activities.interval.min': 'Min: {duration}',
      'activities.interval.max': 'Max: {duration}',
      'activities.interval.total': 'Total: {count} intervals',
      'addActivity.title.new': 'Add Activity',
      'addActivity.title.edit': 'Edit Activity',
      'addActivity.name.label': 'Activity name',
      'addActivity.name.hint': 'Study, meeting, workout...',
      'addActivity.category.label': 'Category',
      'addActivity.category.new': 'New category...',
      'addActivity.category.hint': 'Write new category',
      'addActivity.provider.label': 'Provider',
      'addActivity.provider.hint': 'Write provider name',
      'addActivity.country.label': 'Country',
      'addActivity.country.search': 'Search country',
      'addActivity.country.hint': 'Select country',
      'addActivity.dateTime.label': 'Date & time',
      'addActivity.color.label': 'Colour',
      'addActivity.color.hex': 'Hexadecimal code',
      'addActivity.color.applyToCategory':
          'Apply this colour to every activity in this category',
      'addActivity.notes.label': 'Notes (Optional)',
      'addActivity.notes.hint': 'Add any note or detail about this activity...',
      'addActivity.button.save': 'Save Activity',
      'addActivity.button.update': 'Update Activity',
      'addActivity.validation.required': 'This field is required',
      'addActivity.validation.duplicate': 'Activity name already exists',
      'addActivity.snackbar.saved': 'Activity saved successfully',
      'addActivity.snackbar.updated': 'Activity updated',
      'network.header': 'Activity Map',
      'network.view.timeline': 'Timeline view',
      'network.view.categories': 'Category view',
      'network.empty.title': 'No activities to display',
      'network.empty.subtitle': 'Add activities to see the map',
      'statistics.header': 'Statistics & Insights',
      'statistics.totalActivities': 'Total Activities',
      'statistics.uniqueActivities': 'Unique Activities',
      'statistics.categories': 'Categories',
      'statistics.providers': 'Providers',
      'statistics.countries': 'Countries',
      'statistics.activeDays': 'Active Days',
      'statistics.categoryDistribution': 'Activities by Category',
      'statistics.providerDistribution': 'Activities by Provider',
      'statistics.countryDistribution': 'Activities by Country',
      'statistics.weeklyFrequency': 'Weekly Frequency',
      'statistics.intervalAnalysis': 'Activity Interval Analysis',
      'statistics.empty': 'No data to display',
      'statistics.empty.subtitle': 'Add activities to view the statistics',
      'statistics.interval.latest': 'Latest:',
      'statistics.interval.average': 'Average:',
      'statistics.interval.min': 'Min: {duration}',
      'statistics.interval.max': 'Max: {duration}',
      'statistics.interval.total': 'Total: {count} intervals',
      'common.yes': 'Yes',
      'common.no': 'No',
      'common.cancel': 'Cancel',
      'common.close': 'Close',
      'common.confirm': 'Confirm',
      'common.error': 'There was a problem',
      'common.success': 'Done!',
      'common.noProvider': 'No provider',
      'common.noCountry': 'No country',
      'common.noCategory': 'No category',
      'common.noNotes': 'No notes',
      'backup.restore': 'Restore',
      'backup.share': 'Share',
      'common.refresh': 'Refresh',
      'common.recent': 'Recent',
      'common.days': 'days',
      'common.hours': 'hours',
      'activities.interval.label': 'Interval',
      'activities.interval.from': 'From',
      'activities.interval.avgLabel': 'Average',
      'activities.firstRecord': 'First record of "{name}"',
      'addActivity.provider.new': 'New provider...',
      'addActivity.color.select': 'Select Colour',
      'network.times': '{count} times',
      'common.monday': 'Mon',
      'common.tuesday': 'Tue',
      'common.wednesday': 'Wed',
      'common.thursday': 'Thu',
      'common.friday': 'Fri',
      'common.saturday': 'Sat',
      'common.sunday': 'Sun',
      'statistics.singleActivity': '({count} activity)',
      'statistics.multipleActivities': '({count} activities)',
      'statistics.interval.totalIntervals': 'Total: {count} intervals',
    },
  };

  static String translate(
    BuildContext context,
    String key, {
    required String fallback,
    Map<String, String>? args,
  }) {
    final languageCode = Localizations.localeOf(context).languageCode;
    var result = fallback;
    if (languageCode != 'es') {
      result = _translations[languageCode]?[key] ?? fallback;
    }
    if (args != null) {
      args.forEach((placeholder, value) {
        result = result.replaceAll('{$placeholder}', value);
      });
    }
    return result;
  }
}

extension AppLocalizationExtension on BuildContext {
  String loc(String key,
      {required String fallback, Map<String, String>? args}) {
    return AppLocalizations.translate(this, key,
        fallback: fallback, args: args);
  }
}
