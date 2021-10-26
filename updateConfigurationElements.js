//@ldelorenzi - Oct 2021
//Input is the Project Name (elementName)

var categoryPath = "Projects"
var category = Server.getConfigurationElementCategoryWithPath(categoryPath);


if (category == null) {
    throw "Configuration element category '" + categoryPath + "' not found or empty!";
}


var elements = category.configurationElements;
var result = [];

//This will be the part that would be queried from the external API in a real-world scenario
if (elementName == 'ProjectA')
{
    var portgroups = ['VLAN3', 'VLAN4','VLAN 6','VLAN 7']
    var vCenterFolders = ['Folder6', 'Folder7']
    var adOUs = ['OU1', 'OU2']
    var puppetRoles = ['master', 'base']
    var hostnamePrefixes = ['asd', 'xyz']
}
else if (elementName == 'ProjectB')
{
    var portgroups = ['VLAN11', 'VLAN12','VLAN 13','VLAN 14']
    var vCenterFolders = ['newFolder1', 'oldFolder4']
    var adOUs = ['OU100', 'OU300']
    var puppetRoles = ['master', 'base']
    var hostnamePrefixes = ['pre', 'post']
}
else if (elementName == 'ProjectC')
{
    var portgroups = ['GENEVE1', 'GENEVE2']
    var vCenterFolders = ['SecretFolder', 'VerySecretFolder']
    var adOUs = ['OU5', 'OU6']
    var puppetRoles = ['master', 'base']
    var hostnamePrefixes = ['dev', 'test']
}
else if (elementName == 'ProjectD')
{
    var portgroups = ['VLANBACKEDSEGMENT1', 'VLANBACKEDSEGMENT24']
    var vCenterFolders = ['notSoSecretFolder', 'HR Folder']
    var adOUs = ['OUX', 'OUY']
    var puppetRoles = ['master', 'base']
    var hostnamePrefixes = ['prod', 'db']
}

for (i = 0; i < elements.length; i++) {
    if (elements[i].name == elementName) {
        //Found project!
        System.log("Updating values for Project " + elementName)
        editableElement = elements[i]
        //Update project with new values
        editableElement.setAttributeWithKey("portgroups",portgroups);
        System.log("Updating Portgroups with: " + portgroups)
        editableElement.setAttributeWithKey("adOUs",adOUs);
        System.log("Updating AD OUs with: " + adOUs)
        editableElement.setAttributeWithKey("vCenterFolders",vCenterFolders);
        System.log("Updating vCenter Folders with: " + portgroups)
        editableElement.setAttributeWithKey("puppetRoles",puppetRoles);
        System.log("Updating Puppet Roles with: " + puppetRoles)
        editableElement.setAttributeWithKey("hostnamePrefixes",hostnamePrefixes);
        System.log("Updating Hostname Prefixes with: " + hostnamePrefixes)
    }
}
