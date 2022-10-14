/**
 * autoRuntime.js v1.0.0
 * Copyright (c) 2020 by SAP SE
 */

/**
 * 'define' is a function which implements the Asynchronous Module Definition API.
 * If it is not already here, use amdefine module that provide it's own
 * implementation to use in Node.js:
 * - Browser environment : define() implementation comes from require.js
 * - Node.js environment : define() implementation comes from amdefine
 * --> See readme.txt > Requirements
 */
if (typeof define !== 'function') { var define = require('amdefine')(module); }

define(['./dateCoder'], function(dateCoder) {

    "use strict";

    /**
     * Constructor of the base class for Robust Regresion and XGBoost js engines
     *
     * @param  {object}  modelDef       The model definition built from the JSON export of the model
     * @param  {object}  scoringTarget  The name of the target variable
     * @param  {object}  targetType     The type of the target variable (integer, number, string, ...)
     * @param  {object}  modelType      The model type (regression, binaryClass or multiClass)
     */
    function AutoEngine(modelDef, scoringTarget, targetType, modelType) {

        this._model = modelDef;
        this._scoringTarget = scoringTarget;
        this._targetType = targetType;
        this._modelType = modelType;
    }

    AutoEngine.prototype.Constants = {
        CONTINUOUS_INFLUENCER: "continuous",
        NOMINAL_INFLUENCER: "nominal",
        ORDINAL_INFLUENCER: "ordinal",
        STORAGE_TYPE_INTEGER: "integer",
        STORAGE_TYPE_STRING: "string",
        STORAGE_TYPE_NUMBER: "number",
        STORAGE_TYPE_DATE: "date",
        STORAGE_TYPE_DATETIME: "datetime",
        INFINITY: "INF",
        MINUS_INFINITY: "-INF",
        BINARY_CLASSIFICATION: "binaryClass",
        MULTI_CLASSIFICATION: "multiClass",
        REGRESSION: "regression",
        OBJECTIVE_TWEEDIE: "reg:tweedie"
    };

    /**
     * Engine default options 
     */
    AutoEngine.prototype.DefaultOptions = {
        "interactions": false
    };

    AutoEngine.prototype._getOption = function(options, option) {
        var optionValue = this.DefaultOptions[option];
        if (optionValue === undefined) {
            throw new Error(`Unknown engine option '${option}'`);
        }
        if (options != null && options[option] != null) {
            optionValue = options[option];
        }
        return optionValue;
    };

    /**
     * Returns the information about the contribution normalization.
     * It must be implemented in subclasses.
     *
     * @return  {object}  An object containing the information about the contribution normalization
     *                    This object must contain both properties 'mean' and 'stdDev'
     */
    AutoEngine.prototype._getContributionNormalization = function() {
        throw new Error("_getContributionNormalization implementation is missing.");
    };


    /**
     * Returns the information about the centered contribution normalization.
     *
     * @return  {object}  An object containing the information about the centered contribution normalization
     *                    This object must contain both properties 'mean' and 'stdDev'
     */
    AutoEngine.prototype._getCenteredContributionNormalization = function() {
        throw new Error("_getCenteredContributionNormalization implementation is missing.");
    };

    /**
     * getScore must be implemented in subclasses
     */
    AutoEngine.prototype.getScore = function(selectedInfluencers) {
        throw new Error("getScore implementation is missing.");
    };

    /**
     * Returns a the normalized contribution value.
     *
     * @param  {number}  contributionValue  The native contribution value
     *
     * @return  {number}  The normalized contribution value
     */
    AutoEngine.prototype._getNormalizedContribution = function(influencer, variable, contributionValue) {
        // We need both: overall centered stddev and per variable contribution mean
        var contributionNormalization = this._getCenteredContributionNormalization();
        if ((contributionNormalization == null || contributionNormalization.stdDev == null)) {
            throw new Error("Error while trying to compute the normalized contribution: overall 'stdDev' properties are missing.");
        }
        var varStats = influencer.contribStats;
        if ((varStats == null) || (varStats.mean == null)) {
            throw new Error("Error while trying to compute the normalized contribution: no 'mean' properties for " + variable + ".");
        }
        return (contributionValue - varStats.mean) / contributionNormalization.stdDev;
    };

    /**
     * Builds a contribution object containing the influencer name and its contribution value.
     *
     * @param  {string}  variable      The influencer name
     * @param  {number}  contribution  The native contribution value
     * @param  {array}   interactions  An array that contains the interactions with all other influencers (AutoGB only)
     */
    AutoEngine.prototype._buildContribution = function(influencer, variable, contribution, interactions) {

        let contributionObject = {
            "influencerName": variable,
            "influencerContribution": contribution,
            "normalizedContribution": this._getNormalizedContribution(influencer, variable, contribution)
        };

        if (interactions) {
            contributionObject.interactions = interactions;
        }

        return contributionObject;
    };

    /**
     * Applies a transformation to an influencer value.
     *
     * @param  {string}  transformation  The transformation to apply
     * @param  {string}  measureValue    The influencer value to which to apply the transformation
     *
     * @return  {integer} The transformation result
     */
    AutoEngine.prototype._applyTransformationOnValue = function(transformation, measureValue) {

        if (transformation == null) {
            // No transformation
            return measureValue;
        }
        var date = new Date(measureValue);
        return dateCoder.applyTransformation(date, transformation);
    };

    /**
     * Determines if a given value is in a condition range.
     *
     * @param  {object}  condition     The condition
     * @param  {number}  measureValue  The value to evaluate
     *
     * @return  {boolean}  True if the value is in the condition range, False otherwise
     */
    AutoEngine.prototype._isInRange = function(condition, measureValue) {

        var rangeMin = condition.min === this.Constants.MINUS_INFINITY ? -Infinity : condition.min;
        var rangeMax = condition.max === this.Constants.INFINITY ? Infinity : condition.max;

        if (measureValue > rangeMin && measureValue < rangeMax) {
            return true;
        }
        if (condition.minIncluded && measureValue === rangeMin) {
            return true;
        }
        if (condition.maxIncluded && measureValue === rangeMax) {
            return true;
        }
        return false;
    };

    /**
     * Find the matching condition for a given value.
     *
     * @param  {array}   conditions    An array of conditions
     * @param  {number}  measureValue  The measure value
     *
     * @return  {object}  matching condition
     */
    AutoEngine.prototype._findMeasureCondition = function(conditions, measureValue) {

        for (var i = 0; i < conditions.length; i++) {
            var condition = conditions[i];
            if (condition.category !== null && this._isInRange(condition, measureValue)) {
                return condition;
            }
        }
    };

    /**
     * Converts a string value to an integer or a number (float) depending on the influencer type.
     *
     * @param  {Object}  influencer  The influencer definition
     * @param  {string}  inputValue  A string value
     *
     * @return  {number}  The converted value as an integer or a number
     */
    AutoEngine.prototype._convertFromString = function(influencer, inputValue) {

        var convertedValue = null;

        switch (influencer.storageType) {
            case this.Constants.STORAGE_TYPE_INTEGER:
                convertedValue = parseInt(inputValue);
                break;
            case this.Constants.STORAGE_TYPE_NUMBER:
                convertedValue = parseFloat(inputValue);
                break;
        }

        // Check NaN
        if (isNaN(convertedValue)) {
            // invalid integer/number = missing value
            convertedValue = null;
        }

        return convertedValue;
    };

    /**
     * Converts a string to a number or an integer depending on the influencer storage.
     * If the input value is not a string, we consider it has already the right type.
     *
     * @param  {object}  influencer  The influencer definition
     * @param  {object}  inputValue  The value to convert as a string or any other type
     *
     * @return  {number}  The converted value as an integer or a number
     */
    AutoEngine.prototype._convertValue = function(influencer, inputValue) {

        var outputValue = inputValue;

        if (typeof inputValue === "string") {

            var localInputValue = inputValue.trim();

            if (influencer.missingString != null && localInputValue === influencer.missingString) {
                // input value is empty
                outputValue = null;
            } else {
                switch (influencer.storageType) {
                    case this.Constants.STORAGE_TYPE_INTEGER:
                    case this.Constants.STORAGE_TYPE_NUMBER:
                        outputValue = this._convertFromString(influencer, localInputValue);
                        break;
                    default: // string, date, datetime
                        outputValue = localInputValue;
                }
            }
        }

        return outputValue;
    };

    /**
     * Extracts influencer nominal values from the influencer encoding description.
     *
     * @param  {Object}  influencer  The influencer definition
     *
     * @return  {array}  An array of nominal values
     */
    AutoEngine.prototype._getCategoriesFromNominal = function(influencer) {

        if (influencer.valueType !== this.Constants.NOMINAL_INFLUENCER) {
            throw new Error("[_getCategoriesFromNominal]: The influencer value type is " + influencer.valueType + " while a nominal influencer is expected.");
        }

        var allCategories = influencer.encoding.reduce(function(finalCategories, currentGroup) {

            if (currentGroup.categories != null) {
                currentGroup.categories.forEach(function(category) {
                    finalCategories.push(category);
                });
            } else if (currentGroup.category != null) {
                finalCategories.push(currentGroup.category);
            }

            return finalCategories;

        }, [] /* initial empty array */ );

        // By default the sort() method sorts the array with the items casted to strings
        if (influencer.storageType === this.Constants.STORAGE_TYPE_INTEGER) {
            return allCategories.sort(function(a, b) { return a - b; });
        } else {
            return allCategories.sort();
        }
    };

    /**
     * Extracts ordinal integer values from the influencer definition.
     *
     * @param  {object}  influencer  The influencer definition
     *
     * @return  {array}  An array of ordinal values
     */
    AutoEngine.prototype._getCategoriesFromOrdinalInteger = function(influencer) {

        if (influencer.valueType !== this.Constants.ORDINAL_INFLUENCER) {
            throw new Error("[_getCategoriesFromOrdinalInteger]: The influencer value type is " + influencer.valueType + " while an ordinal influencer is expected.");
        }

        var that = this;
        var allValues = influencer.encoding.reduce(function(finalValues, range) {

            var minValue = null;
            var maxValue = null;

            if (range.min === that.Constants.MINUS_INFINITY && range.max !== that.Constants.INFINITY && range.maxIncluded === true) {
                minValue = parseInt(range.max);
                maxValue = minValue;
            } else if (range.min !== that.Constants.MINUS_INFINITY && range.minIncluded === true && range.max === that.Constants.INFINITY) {
                minValue = parseInt(range.min);
                maxValue = minValue;
            } else if (range.min !== that.Constants.MINUS_INFINITY || range.max !== that.Constants.INFINITY) {
                minValue = parseInt(range.min);
                if (range.minIncluded === false) {
                    minValue++;
                }

                maxValue = parseInt(range.max);
                if (range.maxIncluded === false) {
                    maxValue--;
                }
            }

            if (minValue != null && maxValue != null) {
                for (var value = minValue; value <= maxValue; value++) {
                    if (!finalValues.includes(value)) {
                        finalValues.push(value);
                    }
                }
            }

            return finalValues;

        }, [] /* initial empty array */ );

        // By default the sort() method sorts the array with the items casted to strings
        return allValues.sort(function(a, b) { return a - b; });
    };

    /**
     * Returns an object which contains some information about the model like
     * the model type, the target name and the target type.
     *
     * @return {Object}  An object containing the model information
     */
    AutoEngine.prototype.getModelInfo = function() {

        return {
            "modelType": this._modelType,
            "target": this._scoringTarget,
            "targetType": this._targetType
        };
    };

    /**
     * Returns an array containing one item per influencer.
     * Each item contains the following properties:
     * - variable = the name of the influencer, i.e. the variable name
     * - valueType = the value type, i.e. "nominal", "ordinale" or "continuous"
     * - storageType = the storage type, i.e. "string", "integer", "number"
     * - values = the list of distinct values from the training dataset for nominal and ordinal values
     * @param {bool} ignoreDecomposition if true, derived influencers are not present in the returned array (only source influence is represented)
     * @return  {array}  An array containing all the model influencers
     */
    AutoEngine.prototype.getInfluencers = function(ignoreDecomposition=true) {

        var influencers = [];
        var influencerMap = {};

        for (var i = 0; i < this._model.influencers.length; i++) {

            var influencer = this._model.influencers[i];
            if (ignoreDecomposition) {
                if (influencerMap[influencer.variable]) {
                    // Ignore data decomposition and return one single influencer for a given date variable
                    continue;
                }
            }

            var influencerDef = {
                "variable": influencer.variable,
                "valueType": influencer.valueType,
                "storageType": influencer.storageType
            };

            switch (influencer.valueType) {
                case this.Constants.NOMINAL_INFLUENCER:
                    influencerDef.values = this._getCategoriesFromNominal(influencer);
                    break;

                case this.Constants.ORDINAL_INFLUENCER:
                    if (influencer.storageType === this.Constants.STORAGE_TYPE_INTEGER) {
                        influencerDef.values = this._getCategoriesFromOrdinalInteger(influencer);
                    }
                    break;
            }

            influencers.push(influencerDef);
            influencerMap[influencer.variable] = influencerDef;
        }

        return influencers;
    };

    /**
     * Constructor for the Robust Regression js engine.
     *
     * @param  {object}  scoringEquation  The scoring equation built from the JSON export of the model
     */
    function K2REngine(scoringEquation) {

        AutoEngine.call(
            this,
            scoringEquation,
            scoringEquation.equation[0].variable,
            scoringEquation.equation[0].outputType,
            'regression');
    }
    K2REngine.prototype = Object.create(AutoEngine.prototype);

    /**
     * Returns the information about the contribution normalization.
     * (this one should not be used anymore)
     * 
     * @return  {object}  An object containing the information about the contribution normalization
     *                    This object must contain both properties 'mean' and 'stdDev'
     */
    K2REngine.prototype._getContributionNormalization = function() {

        return this._model.contributionNormalization;
    };

    /**
     * Returns the information about the centered contribution normalization.
     *
     * @return  {object}  An object containing the information about the centered contribution normalization
     *                    This object must contain both properties 'mean' and 'stdDev'
     */
    K2REngine.prototype._getCenteredContributionNormalization = function() {
        return this._model.centeredContributionNormalization;
    };

    /**
     * Return the statistics of one variable contribution.
     * 
     * @return  {object}  An object containing the statistics if the variable contributions
     *                    This object must contain both properties 'mean' and 'stdDev'
     */
    K2REngine.prototype._getVariableContribStats = function(variable) {

        return this._model.influencers[variable].contribStats;
    };


    /**
     * Applies the condition formula to a value.
     *
     * @param  {oject}   condition  The condition object from the influencer encoding
     * @param  {number}  value      The value to which to apply the condition formula
     *
     * @return  {number}  The resulting number
     */
    K2REngine.prototype._executeMeasureFormula = function(condition, value) {

        if (!Number.isFinite(value))
            return condition.intercept;

        var tmpRes = condition.slope * value + condition.intercept;

        if (condition.formula == "1.0/(1.0+exp(-(slope*x+intercept)))")
            return 1.0 / (1.0 + Math.exp(-tmpRes));

        if (condition.formula == "1.0/(exp(-(slope*x+intercept)))")
            return 1.0 / Math.exp(-tmpRes);

        if (condition.formula == "slope*x+intercept")
            return tmpRes;

        return null;
    };

    /**
     * Checks if a value matches a given category.
     *
     * @param  {string|array}  category        The category or an array of categories
     * @param  {string}        dimensionValue  The dimension value
     *
     * @return  {boolean}  True if the value matches the given categories
     */
    K2REngine.prototype._existDimensionValue = function(category, dimensionValue) {

        return dimensionValue === category ||
            Array.isArray(category) &&
            category.some(function(categoryValue) { return categoryValue === dimensionValue; });
    };

    /**
     * Gets the measure contribution.
     *
     * @param  {object}  influencer    The influencer definition
     * @param  {number}  measureValue  The measure value
     *
     * @return  {number}  The measure contribution
     */
    K2REngine.prototype._getMeasureContribution = function(influencer, measureValue) {

        if (influencer.transformation != "AsIs")
            measureValue = this._applyTransformationOnValue(influencer.transformation, measureValue);

        // if measureValue is null or undefined, return default value
        if (measureValue === undefined || measureValue === null) {
            return influencer.missingValue;
        }

        var conditions = influencer.encoding;
        var measureCondition = this._findMeasureCondition(conditions, measureValue);

        if (!measureCondition) {
            return influencer.defaultValue;
        }

        return this._executeMeasureFormula(measureCondition, measureValue);
    };

    /**
     * Gets the dimension contribution.
     *
     * @param  {object}  influencer      The influecer object
     * @param  {string}  dimensionValue  The dimension value
     *
     * @return  {number}  The dimension contribution.
     */
    K2REngine.prototype._getDimensionContribution = function(influencer, dimensionValue) {

        // if dimensionValue is null or empty string or undefined, return missing value
        if (dimensionValue === undefined || dimensionValue === null || dimensionValue === "") {
            return influencer.missingValue;
        }

        var conditions = influencer.encoding;
        for (var i = 0; i < conditions.length; i++) {
            var condition = conditions[i];
            if (this._existDimensionValue(condition.categories, dimensionValue)) {
                return condition.encodedValue;
            }
        }

        // No match = return the default value
        return influencer.defaultValue;
    };

    /**
     * Builds a map containing the influencers, with the influencer name as key.
     *
     * @param  {array}  selectedInfluencers  The variable values as an array of objects { "variable": <variable name>, "value": <var value> }
     *
     * @return  {object}  The scoring equation map
     */
    K2REngine.prototype._buildSelectedInfluencersMap = function(selectedInfluencers) {

        return selectedInfluencers.reduce(function(selectedInfluencersMap, selectedInfluencer) {
            selectedInfluencersMap[selectedInfluencer.variable] = selectedInfluencer;
            return selectedInfluencersMap;
        }, {});
    };

    /**
     * Gets the score for a given observation.
     *
     * @param  {array}   selectedInfluencers  The selected influencers as an array of objects containing the properties "variable" and "value"
     *
     * @return  {Object}  The score object
     */
    K2REngine.prototype.getScore = function(selectedInfluencers) {

        var selectedInfluencersMap = this._buildSelectedInfluencersMap(selectedInfluencers);

        // build contribution array
        var that = this;
        var score = 0;
        var contributionArray = this._model.influencers.map(function(influencer) {

            var contributionValue;
            var selectedInfluencer = selectedInfluencersMap[influencer.variable];

            if (selectedInfluencer == null) {
                // The model influencer is not part of the current case
                contributionValue = influencer.missingValue;
            } else {
                var inputValue = that._convertValue(influencer, selectedInfluencer.value);
                switch (influencer.valueType) {
                    case that.Constants.CONTINUOUS_INFLUENCER:
                    case that.Constants.ORDINAL_INFLUENCER:
                        contributionValue = that._getMeasureContribution(influencer, inputValue);
                        break;
                    case that.Constants.NOMINAL_INFLUENCER:
                        contributionValue = that._getDimensionContribution(influencer, inputValue);
                        break;
                    default:
                        throw new Error("Unknown Influencer Type: " + influencer.valueType);
                }
            }

            score += contributionValue;

            var influencerName = influencer.variable;
            if (influencer.storageType == that.Constants.STORAGE_TYPE_DATE || influencer.storageType == that.Constants.STORAGE_TYPE_DATETIME) {
                influencerName += dateCoder.getTransformationSuffix(influencer.transformation);
            }

            return that._buildContribution(influencer, influencerName, contributionValue);
        });

        // update score based on target condition
        var targetEquation = this._model.equation.find(function(targetEquation) { return targetEquation.variable === that._scoringTarget; });
        var targetCondition = this._findMeasureCondition(targetEquation.transformations, score);
        var finalScore = this._executeMeasureFormula(targetCondition, score);

        if (targetEquation.outputType === this.Constants.STORAGE_TYPE_INTEGER) {
            /*
             * To convert the score to an integer, we want the same
             * behavior as the Kernel which uses a static cast that
             * removes the decimal part of a number.
             */
            finalScore = Math.trunc(finalScore);
        }

        return {
            "score": finalScore,
            "contributionArray": contributionArray
        };
    };

    /**
     * Constructor for the XGBoost js engine
     *
     * @param  {object}  modelDefinition  The XGboost model defintion built from the JSON export of the model
     */
    function KGBEngine(modelDefinition) {

        AutoEngine.call(
            this,
            modelDefinition,
            modelDefinition.info.target.variable,
            modelDefinition.info.target.storage,
            modelDefinition.info.modelType);

        // Build a map from the feature name (F0, F1, ...) to the influencer definition
        this._features = modelDefinition.influencers.reduce(function(featureMap, influencer) {
            featureMap[influencer.encodedVariable] = influencer;
            return featureMap;
        }, { /* empty map as initial accumulator */ });

        /*
         * Build a map from the variable name to a list of influencer definitions:
         * - in case of a date, one influencer for each data component (Year, DayOfMonth, etc)
         * - a single influencer otherwise
         */
        this._influencerByVariable = modelDefinition.influencers.reduce(function(influencerByVar, influencer) {
            if (influencerByVar[influencer.variable] == null) {
                influencerByVar[influencer.variable] = [];
            }
            influencerByVar[influencer.variable].push(influencer);
            return influencerByVar;
        }, { /* empty map as initial accumulator */ });
    }
    KGBEngine.prototype = Object.create(AutoEngine.prototype);

    KGBEngine.prototype.KgbConstants = {

        // LEAF PROPERTIES
        LEAF_VALUE: 0,
        LEAF_COVER: 1,
        LEAF_PROP_COUNT: 2,

        // NODE_PROPERTIES
        NODE_FEATURE: 0,
        NODE_THRESHOLD: 1,
        NODE_YES_PATH: 2,
        NODE_NO_PATH: 3,
        NODE_MISSING: 4,
        NODE_COVER: 5,
        NODE_PROP_COUNT: 6
    };

    /**
     * Returns the information about the contribution normalization.
     *
     * @return  {object}  An object containing the information about the contribution normalization
     *                    This object must contain both properties 'mean' and 'stdDev'
     */
    KGBEngine.prototype._getContributionNormalization = function() {

        return this._model.info.contributionNormalization;
    };

    /**
     * Returns the information about the centered contribution normalization.
     *
     * @return  {object}  An object containing the information about the centered contribution normalization
     *                    This object must contain both properties 'mean' and 'stdDev'
     */
    KGBEngine.prototype._getCenteredContributionNormalization = function() {

        return this._model.info.centeredContributionNormalization;
    };

    /**
     * Gets an array of initial score for each class.
     *
     * @return {array}  An array containing the base score for each class
     */
    KGBEngine.prototype._getInitialScores = function() {

        var numberOfClasses = this._model.info.numberOfClasses;
        var initialScoreByClass = new Array(numberOfClasses);
        for (var classIndex = 0; classIndex < numberOfClasses; classIndex++) {
            initialScoreByClass[classIndex] = this._model.info.baseScore;
        }
        return initialScoreByClass;
    };

    /**
     * Gets the regression score from the xgboost native score.
     *
     * @param  {array}  predictionByClass  An array containing a single element as the xgboost native score
     *
     * @return  {object}  An object containing the regression result as a 'score' property
     */
    KGBEngine.prototype._getRegressionScore = function(predictionByClass) {

        // Regression = one single class
        var score = predictionByClass[0];

        if (this._model.info.objective == this.Constants.OBJECTIVE_TWEEDIE) {
            score = Math.exp(score);
        }
        
        if (this._model.info.target.scaling) {
            score = score * this._model.info.target.scaling.stdDev + this._model.info.target.scaling.mean;
        }

        if (this._model.info.target.storage === this.Constants.STORAGE_TYPE_INTEGER) {
            score = Math.round(score);
        }

        return {
            "score": score
        };
    };

    /**
     * Gets the binary classification prediction from the xgboost native score.
     *
     * @param  {array}  predictionByClass  An array containing a single element as the xgboost native score
     *
     * @return  {object}  An object containing the binary classification result as 'proba', 'decision' and 'score' properties
     */
    KGBEngine.prototype._getBinaryClassificationDecision = function(predictionByClass) {

        // Binary classification = one single class
        var prediction = predictionByClass[0];
        var proba = 1 / (1 + Math.exp(-prediction));

        return {
            "proba": proba,
            "decision": proba > this._model.info.binaryDecisionThreshold ? this._model.info.target.positiveClass : this._model.info.target.negativeClass,
            "score": prediction
        };
    };

    /**
     * Gets the multi classification prediction from the xgboost native score.
     *
     * @param  {array}  predictionByClass  An array containing the xgboost native score for each class
     *
     * @return  {object}  An object containing the binary classification result as 'proba', 'decision' and 'classIndex' properties
     */
    KGBEngine.prototype._getMultiClassificationDecision = function(predictionByClass) {

        // Compute Math.exp(<pred class 0>) + ... + Math.exp(<pred class N>)
        var predictionExpSum = predictionByClass.reduce(function(acc, value) { return acc + Math.exp(value); }, 0);

        // Get the decision class index from the maximum probability
        var prediction = {
            "proba": 0,
            "decision": null,
            "classIndex": 0,
        };

        predictionByClass.forEach(function(value, index) {
            var currentProba = Math.exp(value) / predictionExpSum;
            if (currentProba > prediction.proba) {
                prediction.proba = currentProba;
                prediction.classIndex = index;
            }
        });

        // Get the decision class itself from the index
        prediction.decision = this._model.info.target.categories[prediction.classIndex];

        return prediction;
    };

    /**
     * Gets the cover property for a given tree node
     *
     * @param  {array}    nodes      An array of tree nodes
     * @param  {integer}  nodeIndex  The index of he node from which to get the cover information
     *
     * @return  {number}  THe cover of the specified tree node
     */
    KGBEngine.prototype._getCover = function(nodes, nodeIndex) {

        var node = nodes[nodeIndex];
        if (this._isLeaf(node)) {
            return node[this.KgbConstants.LEAF_COVER];
        } else {
            return node[this.KgbConstants.NODE_COVER];
        }
    };

    /**
     * Checks if a given node is a leaf.
     *
     * @param  {object}  node  The specified node
     *
     * @return  {boolean} True if the node is a leaf, False otherwise
     */
    KGBEngine.prototype._isLeaf = function(node) {

        return (node.length === this.KgbConstants.LEAF_PROP_COUNT);
    };

    KGBEngine.prototype._treeShapUnwindPath = function(uniquePath, pathDepth, pathIndex) {

        var nextOnePortion = uniquePath[pathDepth].weight;
        var pathElement = uniquePath[pathIndex];
        for (var i = pathDepth - 1; i >= 0; i--) {
            if (pathElement.oneFraction != 0) {
                var prevPathWeight = uniquePath[i].weight;
                uniquePath[i].weight = (nextOnePortion * (pathDepth + 1)) / ((i + 1) * pathElement.oneFraction);
                nextOnePortion = prevPathWeight - uniquePath[i].weight * pathElement.zeroFraction * (pathDepth - i) / (pathDepth + 1);
            } else {
                uniquePath[i].weight = (uniquePath[i].weight * (pathDepth + 1)) / (pathElement.zeroFraction * (pathDepth - i));
            }
        }
        for (i = pathIndex; i < pathDepth; i++) {
            uniquePath[i].parentSplitFeature = uniquePath[i + 1].parentSplitFeature;
            uniquePath[i].zeroFraction = uniquePath[i + 1].zeroFraction;
            uniquePath[i].oneFraction = uniquePath[i + 1].oneFraction;
        }
    };

    KGBEngine.prototype._treeShapUnwoundPathSum = function(uniquePath, uniqueDepth, pathIndex) {

        var nextOnePortion = uniquePath[uniqueDepth].weight;
        var pathElement = uniquePath[pathIndex];
        var total = 0;
        for (var i = uniqueDepth - 1; i >= 0; i--) {
            if (pathElement.oneFraction != 0) {
                var tmp = (nextOnePortion * (uniqueDepth + 1)) / ((i + 1) * pathElement.oneFraction);
                total += tmp;
                nextOnePortion = uniquePath[i].weight - tmp * pathElement.zeroFraction * (uniqueDepth - i) / (uniqueDepth + 1);
            } else {
                total += (uniquePath[i].weight / pathElement.zeroFraction) / ((uniqueDepth - i) / (uniqueDepth + 1));
            }
        }
        return total;
    };

    // we use a different permutation weighting for Shapley-Taylor interactions as if the total number of features was one larger
    KGBEngine.prototype._treeShapUnwoundPathSumInteractions = function(uniquePath, uniqueDepth, pathIndex) {

        var nextOnePortion = uniquePath[uniqueDepth].weight;
        var pathElement = uniquePath[pathIndex];
        var total = 0;
        for (var i = uniqueDepth - 1; i >= 0; i--) {
            if (pathElement.oneFraction != 0) {
                var tmp = (nextOnePortion * (uniqueDepth - i)) / ((i + 1) * pathElement.oneFraction);
                total += tmp;
                nextOnePortion = uniquePath[i].weight - tmp * pathElement.zeroFraction;
            } else {
                total += uniquePath[i].weight / pathElement.zeroFraction;
            }
        }
        return 2 * total;
    };

    KGBEngine.prototype._treeShapExtend = function(uniquePath, pathDepth, zeroFraction, oneFraction, parentSplitFeature) {

        var itemsToRemove = uniquePath.length - pathDepth;
        if (itemsToRemove > 0) {
            uniquePath.splice(pathDepth);
        }
        uniquePath.push({
            "parentSplitFeature": parentSplitFeature,
            "zeroFraction": zeroFraction,
            "oneFraction": oneFraction,
            "weight": pathDepth == 0 ? 1 : 0
        });
        for (var i = pathDepth - 1; i >= 0; i--) {
            uniquePath[i + 1].weight += oneFraction * uniquePath[i].weight * (i + 1) / (pathDepth + 1);
            uniquePath[i].weight = zeroFraction * uniquePath[i].weight * (pathDepth - i) / (pathDepth + 1);
        }
    };

    KGBEngine.prototype._copyPathElements = function(pathElements) {

        return pathElements.map(function(pathElement) {
            return {
                "parentSplitFeature": pathElement.parentSplitFeature,
                "zeroFraction": pathElement.zeroFraction,
                "oneFraction": pathElement.oneFraction,
                "weight": pathElement.weight
            };
        });
    };

    /**
     * Recusrsive function to update shap values from a given decision tree
     * Input parameters 'condition', 'conditionFeature' and 'conditionFraction' are
     * used when calculating interactions only. In the other case, their value is
     * always the same acrosss recursive calls:
     * - condition = 0
     * - conditionFeature = null
     * - conditionFraction = 1
     */
    KGBEngine.prototype._treeShapRecurse = function(
        row, shapValues, nodes, nodeIndex, parentUniquePath, pathDepth,
        zeroFraction, oneFraction, parentSplitFeature,
        condition, conditionFeature, conditionFraction) {

        var node = nodes[nodeIndex];
        var localUniquePath = this._copyPathElements(parentUniquePath);

        if (condition === 0 || conditionFeature !== parentSplitFeature) {
            this._treeShapExtend(localUniquePath, pathDepth, zeroFraction, oneFraction, parentSplitFeature);
        }

        if (this._isLeaf(node)) {
            for (var i = 1; i <= pathDepth; i++) {
                if (condition === 0) {
                    var weight = this._treeShapUnwoundPathSum(localUniquePath, pathDepth, i);
                } else {
                    var weight = this._treeShapUnwoundPathSumInteractions(localUniquePath, pathDepth, i);
                }
                var pathElement = localUniquePath[i];
                shapValues[pathElement.parentSplitFeature] += weight * (pathElement.oneFraction - pathElement.zeroFraction) * node[this.KgbConstants.LEAF_VALUE] * conditionFraction;
            }
        } else {
            var hotIndex = this._getHotIndex(node, row);
            var coldIndex = hotIndex === node[this.KgbConstants.NODE_YES_PATH] ? node[this.KgbConstants.NODE_NO_PATH] : node[this.KgbConstants.NODE_YES_PATH];
            var nodeCover = this._getCover(nodes, nodeIndex);
            var hotZeroFraction = this._getCover(nodes, hotIndex) / nodeCover;
            var coldZeroFraction = this._getCover(nodes, coldIndex) / nodeCover;
            var incomingZeroFraction = 1;
            var incomingOneFraction = 1;
            var splitFeature = node[this.KgbConstants.NODE_FEATURE];
            var splitPathIndex = 0;
            for (; splitPathIndex <= pathDepth; splitPathIndex++) {
                if (localUniquePath[splitPathIndex].parentSplitFeature === splitFeature) {
                    break;
                }
            }
            if (splitPathIndex != pathDepth + 1) {
                incomingZeroFraction = localUniquePath[splitPathIndex].zeroFraction;
                incomingOneFraction = localUniquePath[splitPathIndex].oneFraction;
                this._treeShapUnwindPath(localUniquePath, pathDepth, splitPathIndex);
                pathDepth -= 1;
            }

            var hotConditionFraction = conditionFraction;
            var coldConditionFraction = conditionFraction;
            if (condition > 0 && splitFeature == conditionFeature) {
                coldConditionFraction = 0;
                pathDepth -= 1;
            } else if (condition < 0 && splitFeature == conditionFeature) {
                hotConditionFraction *= hotZeroFraction;
                coldConditionFraction *= coldZeroFraction;
                pathDepth -= 1;
            }

            this._treeShapRecurse(
                row, shapValues, nodes, hotIndex, localUniquePath, pathDepth + 1,
                incomingZeroFraction * hotZeroFraction, incomingOneFraction, splitFeature,
                condition, conditionFeature, hotConditionFraction);

            this._treeShapRecurse(
                row, shapValues, nodes, coldIndex, localUniquePath, pathDepth + 1,
                incomingZeroFraction * coldZeroFraction, 0, splitFeature,
                condition, conditionFeature, coldConditionFraction);
        }
    };

    /**
     * Initialize a map of shap values with zero.
     *
     * @return {map}  A map containing zero as initial shap value for each feature
     */
    KGBEngine.prototype._initShapValues = function() {

        return this._model.influencers.reduce(function(shapValues, influencer) {
            shapValues[influencer.encodedVariable] = 0;
            return shapValues;
        }, { /* Empty map as initial accumulator */ });
    };

    /**
     * Gets a map containing the shap value for each feature.
     *
     * @param  {map}      encodedRow          A map containing the encoded value for each feature
     * @param  {integer}  decisionClassIndex  The index of the predicted class
     * @param  {integer}  condition           The condition to calculate interactions: 0 = no interaction; -1 = feature is Off; 1 = featiure is On
     * @param  {string}   conditionFeature    The feature for which we calculate the interactions
     *
     * @return  {map}  A map containing the shap value for each feature
     */
    KGBEngine.prototype._getShapValues = function(encodedRow, decisionClassIndex, condition, conditionFeature) {

        var shapValues = this._initShapValues();
        var numberOfTreesPerClass = this._model.trees.length / this._model.info.numberOfClasses;
        for (var currentIteration = 0; currentIteration < numberOfTreesPerClass; currentIteration++) {
            var globalTreeIndex = currentIteration * this._model.info.numberOfClasses + decisionClassIndex;
            this._treeShapRecurse(
                encodedRow, shapValues, this._model.trees[globalTreeIndex],
                0, [], 0, 1, 1, null,
                condition, conditionFeature, 1);
        }
        return shapValues;
    };

    /**
     * Builds an interaction object based on a feature name and an interaction value
     * 
     * @param  {string}    feature      The feature name
     * @param  {number}    interaction  The interaction value
     * 
     * @return {object}    An interaction object containing the feature name and the interaction value as { "variable": <string>, "interaction": <number> }
     */
    KGBEngine.prototype._buildInteraction = function(feature, interaction) {
        return {
            "variable": feature,
            "interaction": interaction
        };
    };

    /**
     * Gets variable interactions
     *
     * @param  {map}      encodedRow          A map containing the encoded value for each feature
     * @param  {integer}  decisionClassIndex  The index of the predicted class
     * @param  {map}      shapValues          A map containing individual SHAP values for each feature
     *
     * @return  {map}  A matrix containing interactions between all influencers, as a map of array
     */
    KGBEngine.prototype._getShapInteractions = function(encodedRow, decisionClassIndex, shapValues) {

        // Get an array containing all features involved in SHAP values
        var features = [];
        this._model.influencers.forEach(function(influencer) {
            if (!influencer.unused &&
                shapValues[influencer.encodedVariable] !== undefined) {
                features.push(influencer.encodedVariable);
            }
        });

        // Interactions output is a matrix with the N features as rows and columns
        // The matrix is stored in a map of arrays
        var interactions = {};

        // Browse features on rows
        var that = this;
        features.forEach(function(rowFeature, rowFeatureIndex) {
            // Initialize the current row of the interaction matrix as an array with the proper length
            interactions[rowFeature] = new Array(features.length);

            // For the current feature, get shap values with and without the feature
            var shapValuesOff = that._getShapValues(encodedRow, decisionClassIndex, /* condition off */ -1, /* condition feature */ rowFeature);
            var shapValuesOn = that._getShapValues(encodedRow, decisionClassIndex, /* condition on */ 1, /* condition feature */ rowFeature);

            // initialize the diagonal value as zero (main effect for the current feature)
            interactions[rowFeature][rowFeatureIndex] = that._buildInteraction(rowFeature, 0);

            // Browse features on columns
            features.forEach(function(colFeature, colFeatureIndex) {
                if (rowFeatureIndex == colFeatureIndex) { // Matrix diagonal = main effect
                    // Add the individual SHAP value
                    interactions[rowFeature][colFeatureIndex].interaction += shapValues[rowFeature];
                } else {
                    var interactionValue = (shapValuesOn[colFeature] - shapValuesOff[colFeature]) / 2;
                    interactions[rowFeature][colFeatureIndex] = that._buildInteraction(colFeature, interactionValue);
                    // Substract this interaction from the inidividual SHAP value, i.e. from the diagonal
                    interactions[rowFeature][rowFeatureIndex].interaction -= interactionValue;
                }
            });
        });

        return interactions;
    };

    /**
     * Gets the index of the next node in the decision tree.
     *
     * @param  {object}  node  The current decision node
     * @param  {map}     row   The map containing the feature values
     *
     * @return  {integer}  The index of the next node in the decision tree
     */
    KGBEngine.prototype._getHotIndex = function(node, row) {

        var feature = node[this.KgbConstants.NODE_FEATURE];
        var featureValue = row[feature];
        if (featureValue === this._features[feature].missingValue) {
            return node[this.KgbConstants.NODE_MISSING];
        } else if (featureValue < node[this.KgbConstants.NODE_THRESHOLD]) {
            return node[this.KgbConstants.NODE_YES_PATH];
        } else {
            return node[this.KgbConstants.NODE_NO_PATH];
        }
    };

    /**
     * Gets the score for a single decision tree.
     *
     * @param  {object}  tree  The decision tree
     * @param  {map}     row   The map containing the feature values
     *
     * @return  {number}  The prediction score for the specified decision tree and observation
     */
    KGBEngine.prototype._predictSingleTree = function(tree, row) {

        var nodeId = 0;
        while (true) {
            let node = tree[nodeId];
            if (this._isLeaf(node)) {
                return node[this.KgbConstants.LEAF_VALUE];
            } else {
                nodeId = this._getHotIndex(node, row);
            }
        }
    };

    /**
     * Encodes a given observation.
     *
     * @param  {array}  selectedInfluencers  The current observation as an array of influencers
     *
     * @return  {Object}  A map containing the encoded values by feature name
     */
    KGBEngine.prototype._encodeCase = function(selectedInfluencers) {

        var that = this;
        return selectedInfluencers.reduce(function(acc, influencerValue, index) {

            var influencerDefinitions = that._influencerByVariable[influencerValue.variable];
            if (influencerDefinitions != null) {
                // Influencer might be null if the variable does not exist in the training dataset
                influencerDefinitions.forEach(function(influencerDef) {
                    var inputValue = that._convertValue(influencerDef, influencerValue.value);
                    acc[influencerDef.encodedVariable] = that._encodeInfluencer(influencerDef, inputValue);
                });
            }
            return acc;

        }, { /* Empty object as initial accumulator */ });
    };

    /**
     * Checks if an influencer value shall be considered as missing.
     *
     * @param  {object}         influencerDef    The influencer definition
     * @param  {string|number}  influencerValue  The influenceer value
     *
     * @return  {boolean}  True if the influencer value should be considered as missing, False otherwise
     */
    KGBEngine.prototype._valueIsMissing = function(influencerDef, influencerValue) {

        if (influencerValue === undefined || influencerValue === null) {
            // Null or undefined value
            return true;
        }

        if (influencerDef.storageType === this.Constants.STORAGE_TYPE_STRING) {
            if (influencerValue === "") {
                // empty string
                return true;
            }
        }

        // The value is not missing...
        return false;
    };

    /**
     * Gets the encoding condition for an ordinal influencer, depending on the input value
     *
     * @param  {array}          conditions  The array containing all encoding conditions
     * @param  {string|number}  value       The value of the influencer
     *
     * @return  {object}  The encoding condition for the influencer value
     */
    KGBEngine.prototype._findOrdinalCondition = function(conditions, value) {

        var that = this;
        return conditions.find(function(elemt) {
            return that._isInRange(elemt, value);
        });
    };

    /**
     * Gets the encoding condition for a nominal influencer, depending on the input value
     *
     * @param  {array}          conditions  The array containing all encoding conditions
     * @param  {string|number}  value       The value of the influencer
     *
     * @return  {object}  The encoding condition for the influencer value
     */
    KGBEngine.prototype._findNominalCondition = function(conditions, value) {

        return conditions.find(function(elemt) {
            return elemt.category === value;
        });
    };

    /**
     * Encodes a given influencer
     *
     * @param  {Object}  influencerDef    The current influencer to encode
     * @param  {Object}  influencerValue  The value of the influencer
     *
     * @return  {number}  The encoded value of the influencer
     */
    KGBEngine.prototype._encodeInfluencer = function(influencerDef, influencerValue) {

        if (influencerDef == null) {
            // unknown influencer : variable has not been trainned = just ignore it
            return null;
        }

        // Check date decomposition
        influencerValue = this._applyTransformationOnValue(influencerDef.transformation, influencerValue);

        // Check missing value
        if (this._valueIsMissing(influencerDef, influencerValue)) {
            return influencerDef.missingValue;
        }

        if (influencerDef.valueType === this.Constants.CONTINUOUS_INFLUENCER) {
            if (influencerDef.storageType == this.Constants.STORAGE_TYPE_NUMBER) {
                /*
                 * Since XGBoost manipulates 32-bit single precision float numbers,
                 * we use Math.fround to convert any number to the nearest 32-bit single precision number
                 */
                var fRounded = Math.fround(influencerValue);
                /*
                 * But this number has still a greater precision than a real simple precision floatting number, which is typically 9
                 * -> fround(14.395) = 14.395000457763672
                 * -> with a cpp float, 14.395 is represented by the value 14.3950005 in memory
                 * -> Then, we can force the precision as 9
                 */
                var withPrecisionAs9 = fRounded.toPrecision(9);
                /*
                 * but Number.toPrecision() returns a string!
                 * -> we have to parse it as a float
                 */
                return Number.parseFloat(withPrecisionAs9);
            } else {
                return influencerValue;
            }
        }

        var condition = null;

        if (influencerDef.valueType === this.Constants.NOMINAL_INFLUENCER) {
            condition = this._findNominalCondition(influencerDef.encoding, influencerValue);
        } else if (influencerDef.valueType === this.Constants.ORDINAL_INFLUENCER) {
            condition = this._findOrdinalCondition(influencerDef.encoding, influencerValue);
        }

        return condition != null ? condition.encodedValue : influencerDef.defaultValue;
    };

    /**
     * Gets the prediction for a given observation.
     *
     * @param  {array}   selectedInfluencers  The selected influencers as an array of objects containing the following properties: "variable", "value"
     * @param  {object}  options              The options for the prediction process
     *
     * @return  {object}  The prediction object depending on the model type
     */
    KGBEngine.prototype.getScore = function(selectedInfluencers, options) {

        var encodedRow = this._encodeCase(selectedInfluencers);
        var that = this;

        // get single scores for each tree
        var treeScores = this._model.trees.map(function(tree) {
            return that._predictSingleTree(tree, encodedRow);
        });

        // Aggregate scores by class
        var predictionByClass = treeScores.reduce(function(scores, score, index) {
            const classIndex = index % that._model.info.numberOfClasses;
            scores[classIndex] += score;
            return scores;
        }, this._getInitialScores());

        var prediction = null;
        var decisionClass = 0;

        switch (this._model.info.modelType) {
            case this.Constants.BINARY_CLASSIFICATION:
                prediction = this._getBinaryClassificationDecision(predictionByClass);
                break;
            case this.Constants.MULTI_CLASSIFICATION:
                prediction = this._getMultiClassificationDecision(predictionByClass);
                decisionClass = prediction.classIndex;
                break;
            case this.Constants.REGRESSION:
                prediction = this._getRegressionScore(predictionByClass);
                break;
        }

        // ShapValues is a map which key is the feature name ("F0", "F1", ...) and the value the Shap value
        var shapValues = this._getShapValues(encodedRow, decisionClass, 0, null);

        var stdDev = this._model.info.target.scaling ? this._model.info.target.scaling.stdDev : 1;

        // Get interactions depending on the option
        var generateInteractions = this._getOption(options, "interactions");
        var interactions =
            generateInteractions ?
            this._getShapInteractions(encodedRow, decisionClass, shapValues, stdDev) : { /* Empty map */ };

        // Transform previous map into an array of contributions and apply scaling if needed
        // skip unused variables
        var contributionArray = this._model.influencers.filter(influencer => !influencer.unused).reduce(function(contribs, influencerDef) {
            var shapValue = shapValues[influencerDef.encodedVariable]; // encodedVariable contains the feature name "Fn"
            if (shapValue != null) { // keep zero shap values
                var influencerName = influencerDef.variable;
                if (influencerDef.transformation != null) {
                    influencerName += dateCoder.getTransformationSuffix(influencerDef.transformation);
                }

                var featureInteractions = interactions[influencerDef.encodedVariable];
                if (generateInteractions) {
                    featureInteractions = featureInteractions.map(function(interactionItem) {
                        return that._buildInteraction(
                            that._features[interactionItem.variable].variable, // Use the real variable name
                            interactionItem.interaction * stdDev); // Unscale the interaction value
                    });
                }

                contribs.push(that._buildContribution(influencerDef, influencerName, shapValue * stdDev, featureInteractions));
            }
            return contribs;
        }, []);

        return {
            "score": prediction.score,
            "decision": prediction.decision,
            "proba": prediction.proba,
            "contributionArray": contributionArray
        };
    };

    /**
     * Returns a the normalized contribution value.
     *
     * @param  {number}  contributionValue  The native contribution value
     *
     * @return  {number}  The normalized contribution value
     */
    KGBEngine.prototype._getNormalizedContribution = function(influencer, variable, contributionValue) {
        var contributionNormalization = this._getContributionNormalization();

        if ((contributionNormalization == null || contributionNormalization.stdDev == null)) {
            throw new Error("Error while trying to compute the normalized contribution: overall 'stdDev' properties are missing.");
        }

        return contributionValue / contributionNormalization.stdDev;
    };

    /*
     * AutoEngine factory implementation
     *
     * The current module exports a single method
     * called createEngine() which is responsible
     * for creating the proper engine depending
     * on the given model definition.
     *
     */

    /**
     * Factory to build an engine depending on the model type (Robust Regression or XGBoost).
     *
     * @param  {object}  modelDef  The model definition
     *
     * @return  {object}  A predictive engine
     */
    function createEngine(modelDef) {

        if (modelDef.equation) {
            return new K2REngine(modelDef);
        }

        return new KGBEngine(modelDef);
    }

    /**
     * This module povides a single method as an engine factory.
     */
    return {
        "createEngine": createEngine
    };
});