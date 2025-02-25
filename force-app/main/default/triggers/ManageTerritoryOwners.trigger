trigger ManageTerritoryOwners on Account (before update) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        AccountPostalCodeHandler.manageTerritoryOwners(Trigger.new, Trigger.oldMap);
    }
}