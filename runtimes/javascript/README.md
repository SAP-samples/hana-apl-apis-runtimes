# Introduction

  The javascript runtime is aimed to be used to make unitary predictions
  based on any predictive model that has been exported in JSON format
  beforehand.
  The runtime supports the following model types:
  - regression
  - binary classification
  - multi-class classification

# Requirements

As a javascript module, this runtime is aimed to be executed in a javascript
environment, i.e. a browser or Node.js.
It leverages the **`Asynchronous Module Definition`** (**`AMD`**) API, and as a 
consequence, it requires a third-party library that implements this API:

## in-Browser environment
  
A popular implementation of the AMD API is `RequireJS`, that can be downloaded here: https://requirejs.org/

Some other implementations are available, like `Dojo Toolkit` (starting from version 1.7.0).

## Node.js environment
  
As an alternative solution for Node.js, you can install the package **`'amdefine'`**, either globally, if you have enough rights, or locally, in the directory where the runtime is
located, or in any parent directory using the following command:

#### global installation

```Shell
npm install -g amdefine
```

#### local installation

```Shell
cd <runtime directory or any parent directory>
npm install amdefine
```

# Runtime content

  The javascript runtime consists of 2 js files:

  - [`autoRuntime.js`](autoruntime.js): Contains the main runtime.
  - [`dateCoder.js`](dateCoder?js): Provides utilities for date encoding. It is loaded by autoRuntime.js.

# Loading the runtime

## in-Browser environment

* Content of `index.html`

```html
<!-- data-main attribute tells to load main.js after require.js is loaded -->
<script
    data-main="<path to script folder>/main"
    src="<path to requirejs folder>/require.js">
</script>
```

* Content of `main.js`

```javascript
require(
    [... , '<path to runtime folder>/autoRuntime', ...],

    function(..., runtime, ...) {
        // use the runtime here...
    }
);
```

## Node.js environment

```javascript
var runtime = require('<path to runtime folder>/autoRuntime');
// use the runtime here...
```

# Using the runtime
Once the runtime is loaded, a typical workflow is:
  1. Create a predictive engine based on the JSON model export
  2. Ask for some model information:
     - model type
     - target
     - target type
  3. Get all model influencers
  4. Build a UI to enter influencer values
  5. Collect entered influencer values
  6. Ask the engine for a prediction based on the entered influencer values

### Step 1:Create a predictive engine based on the JSON model export:

```javascript
var engine = runtime.createEngine(jsonExportAsObject);
```

The input parameter of the method createEngine must be a real json object. Depending on how you get the JSON model export, it might be a string, in which case you can simply convert it to an object this way:

```javascript
var jsonExportAsObject = JSON.parse(jsonExportAsString);
```

### Step 2: Ask for some model information:
Once the predictive engine is created, you can ask for some general information about the model:

```javascript
var modelInfo = engine.getModelInfo();
```

Output:

```json
{
    "modelType": "regression" | "binaryClass" | "multiClass"
    "target": <string>        // The name of the target variable
    "targetType": "number" | "integer" | "string" | ... 
    }
```

### Step 3: Ask for the model influencers:

```javascript  
var modelInfluencers = engine.getInfluencers();
```     
The method getInfluencers() returns an array which contains all the influencers of the model.

Each item of the array is an object that contains the following properties:

```json
{
    "variable": <string>      // The name of the influencer
    "valueType": "continuous" | "nominal" | "ordinal"
    "storageType": "number" | "integer" | "[u]string" | "date[time]"
    "values": <array>
}
```

The property "values" is an array that contains all the distinct known values of an influencer of type nominal or ordinal integer. A known value is contained in the train dataset.

### Step 4: Build a UI to enter influencer values
Using the information about the influencers, it is possible to build a dynamic UI to allow the user entering influencer values for prediction simulations.

### Step 5: Collect entered influencer values
The values that have been entered by the user can be collected and formated  as an array which items contain the following properties:

```json
{
    "variable": <string>         // The name of the influencer
    "value": <any>               // the value of the influencer
}
```

### Step 6: Ask for a prediction:

Once the influencer values have been collected and formated as described above, it is possible to ask the engine for a prediction by calling **`getScore()`** API:

```javascript
var prediction = engine.getScore(values, options);
```

#### Input Parameters:
* values: an array containing the values of the influencers, as described in #5
* options: an optional object containing the prediction options:

```json
{
    "interactions": true | false    // true to generate the interactions; false by default
}
```

#### Output:

```javascript
{
    "score": <number>              // The prediction score = regression result
    "decision": <any>              // The prediction decision (for binary or multi-class classification)
    "proba": <number>              // The probability of the decision (for binary or multi-class classification)
    "contributionArray" : <array>  // An array that contains the contribution of each influencer 
}
```

Each item of the array of contributions contains the following properties:

```javascript
{
    "influencerName": <string>          // The name of the influencer
    "influencerContribution": <number>  // The raw contribution of the influencer
    "normalizedContribution": <number>  // The normalized contribution of the influencer
    "interactions": <array>             // array of interactions if options.interactions is true
}
```

The property **`normalizedContribution`** contains the z-score of the influencer contribution, that illustrates the relation between the contribution value and the mean of the contributions.

Assuming the contribution values follow a normal distribution, it means we can refer to the empirical rule, i.e. the **`three-sigma`** rule, or the **`68-95-99.7`** rule:
- 68% of the observations falls between the mean and one standard deviation (sigma)
- 95% of the observations falls between the mean and two standard deviations
- 99% of the observations falls between the mean and three standard deviations

As a consequence, the strength of each contribution can be evaluated in light of the normalized value.
For example:
- normalize contribution < 1       = weak contribution 
- 1 <= normalize contribution < 2  = meaningfull contribution
- normalize contribution > 2       = strong contribution

In case **`options.interactions`** is **`true`**, the influencer contribution contains an additional property called **`"interactions"`** that contains an array of interaction values:

```javascript
{
    "variable": <string>      // The name of the influencer the current influencer is interacting with
    "interaction": <number>   // The value of the interaction
}
```

Here is a full prediction object example:

```javascript
{
    "score": 1.234,         // The final prediction for a regression
    "decision": "1",        // The predicted class for a binary or multi-class classification
    "proba": 0.789,         // The prediction probability for a binary or multi-class classification
    "contributionArray": [
        {
            "influencerName": "var1",
            "influencerContribution": 1.123,
            "normalizedContribution": 1.456,
            "interactions": [
                {
                    "variable": "var1",
                    "interaction": 5.432   // interaction btw. 'var1' and 'var1' = The Main Effect for 'var1' 
                },
                {
                    "variable": "var2",
                    "interaction": 1.234
                },
                ...
            ]
        },
    ...
    ]
}
```

# Notes

- The interactions are available for **gradient boosting** models only.
- The array of interactions contains a value for the interaction between the current influencer and itself. This value is called the main effect. The sum of all other interaction values is called the interaction effect.
- For a given influencer, the sum of all the interaction values, i.e. the main effect plus the interaction effect, is equal to the influencer contribution.
