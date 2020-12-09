WeatherApp
==========

This is a concept weather application written in Objective-C for iOS.

It was one of my very first iOS projects. I presented the application and submitted the code for a competitive event in which I placed first in Indiana and second nationally.

Powered by Wunderground, WeatherApp has a minimalistic UI design with rotating public domain imagery. Unique features which might distingish it from the stock Weather app include inclement weather notifications and access to more detailed forecasts and historic weather data.

## Code navigation

Backend
* [WALocation](./WeatherApp/WALocation.m) - location object class
* [WALocationManager](./WeatherApp/WALocationManager.m) - location manager class
* [WAAppDelegate](./WeatherApp/WAAppDelegate.m) - the application delegate

MVC
* [WALocationCell](./WeatherApp/WALocationCell.m) - table cell representing a location, which is drawn from code
* [WAPageViewController](./WeatherApp/WAPageViewController.m) - page view controller implementation for swiping between locations
* [WAMenu](./WeatherApp/WAMenu) - custom drop-down menu implementation
* [WADailyForecastTVC](./WeatherApp/WADailyForecastTVC.m) - table view controller for daily forecasts
* [WAHourlyForecastTVC](./WeatherApp/WAHourlyForecastTVC.m) - table view controller for hourly forecasts
* [WANewLocationTVC](./WeatherApp/WANewLocationTVC.m) - table view controller for searching/adding locations
* [WASettingsTVC](./WeatherApp/WASettingsTVC.m) - table view controller for app settings

[![Screenshots](https://i.imgur.com/6UsMTC4.png) Screenshot gallery](https://mitchellcooper.me/screenshots/weatherapp)
