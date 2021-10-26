//@ldelorenzi - Oct 2021
//Inputs should be elementName (Project) and attributeName (The value we want)
var categoryPath = "Projects"
System.log (categoryPath)
var category = Server.getConfigurationElementCategoryWithPath(categoryPath);
if (category == null) {
    throw "Configuration element category '" + categoryPath + "' not found or empty!";
}
var elements = category.configurationElements;
for (i = 0; i < elements.length; i++) {
    if (elements[i].name == elementName) {
        //found required element
        var attribute = elements[i].getAttributeWithKey(attributeName);
        if (attribute != null) {
            System.log("Found attribute '" + attributeName + "' in '" + elementName + "' with value '" + attribute.value + "'");
            return attribute.value
        }
        else {
            throw "Attribute '" + attributeName + "' not found!";
        }
    }
}
