# 🎈 Breathe Easy

An air quality map application that provides routes ranked on air quality for walking between two places. It features autocomplete for location inputs.

![image](https://raw.githubusercontent.com/Joeweh/BreatheEasy/basiclayout/assets/mobile-demo-6-1-2024.png)

## 🔧 Features

1. Autocomplete for Directions

    - Dynamic and user-friendly autocomplete feature for entering starting and destination locations.
    - Integration with location services for accurate and quick suggestions.

2. Routes Ranked on Air Quality

    - Routes are calculated, rendered, and ranked based on real-time air quality data.
    - Users can select the healthiest walking path between two points.

3. Easily Readable Walking Directions

    - Clear and concise walking directions displayed for each route.
    - Turn-by-turn navigation instructions to ensure easy following.

4. Glanceable Statistics

    - Miles: Displays the total distance for each route.
    - Time: Estimated time to complete the route.
    - Air Quality Ranking: Ranks routes based on air quality for easy comparison.

## 📝 Requirements
- google maps api key
    - Get google maps api key with places and routes api enabled
- .env file
    - Create a .env file in the BreatheEasy directory containing this line: MAPS_API_KEY=[GOOGLE MAPS API KEY]
- index.html (web view only)
    - Replace %MAPS_API_KEY% with [GOOGLE MAPS API KEY]

(Mobile and Desktop App Not Implemented Yet)

## 🚀 Usage
1. Click on the Text Fields below the Map to enter the autocomplete page

![alt text](https://raw.githubusercontent.com/Joeweh/BreatheEasy/basiclayout/assets/text-field-image-6-1-2024.png)

2. Click on a suggested address to return to the map page

![alt text](https://github.com/Joeweh/BreatheEasy/blob/basiclayout/assets/autocomplete-image-6-1-2024.png?raw=true)

3. After two addresses are selected, use slider to select route

![alt text](https://raw.githubusercontent.com/Joeweh/BreatheEasy/basiclayout/assets/routes-image-6-1-2024.png)

4. Click start route to get directions

![alt text](https://raw.githubusercontent.com/Joeweh/BreatheEasy/basiclayout/assets/directions-image-6-1-2024.png)

## 🔎 Tools Used
- Flutter SDK
- Dart
    - Shelf Package (for server)
- Docker (container for hosting)
- Postman (testing api)
- Google Maps API

## 🔗 Links
- Devpost: https://devpost.com/software/breathe-easy-lanuqf?ref_content=my-projects-tab&ref_feature=my_projects
- Server Repo: https://github.com/Joeweh/BreatheEasyServer