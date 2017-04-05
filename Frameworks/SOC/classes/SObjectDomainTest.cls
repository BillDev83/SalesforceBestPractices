@IsTest
private with sharing class SObjectDomainTest
{
    private static String OBJECT_NAME = 'Account';

    @IsTest
    private static void testValidationWithoutDML()
    {
        SObjectDomain.TestSObjectDomain opps = new SObjectDomain.TestSObjectDomain(new Opportunity[] { new Opportunity ( Name = 'Test', Type = 'Existing Account' ) } );
        opps.onValidate();
        System.assertEquals(1, SObjectDomain.Errors.getAll().size());
        System.assertEquals('You must provide an Account for Opportunities for existing Customers.', SObjectDomain.Errors.getAll()[0].message);
        System.assertEquals(Opportunity.AccountId, ((SObjectDomain.FieldError)SObjectDomain.Errors.getAll()[0]).field);

        opps = new SObjectDomain.TestSObjectDomain(new SObject[] { new Opportunity ( Name = 'Test', Type = 'Existing Account' ) }, Opportunity.SObjectType );
        System.assertEquals(1, SObjectDomain.Errors.getAll().size());
        System.assertEquals('You must provide an Account for Opportunities for existing Customers.', SObjectDomain.Errors.getAll()[0].message);
        System.assertEquals(Opportunity.AccountId, ((SObjectDomain.FieldError)SObjectDomain.Errors.getAll()[0]).field);
    }

    @IsTest
    private static void testInsertValidationFailedWithoutDML()
    {
        Opportunity opp = new Opportunity ( Name = 'Test', Type = 'Existing Account' );
        System.assertEquals(false, SObjectDomain.Test.Database.hasRecords());
        SObjectDomain.Test.Database.onInsert(new Opportunity[] { opp } );
        System.assertEquals(true, SObjectDomain.Test.Database.hasRecords());
        SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDomainConstructor.class);
        System.assertEquals(1, SObjectDomain.Errors.getAll().size());
        System.assertEquals('You must provide an Account for Opportunities for existing Customers.', SObjectDomain.Errors.getAll()[0].message);
        System.assertEquals(Opportunity.AccountId, ((SObjectDomain.FieldError)SObjectDomain.Errors.getAll()[0]).field);
    }

    @IsTest
    private static void testUpdateValidationFailedWithoutDML()
    {
        Opportunity oldOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
        oldOpp.Name = 'Test';
        oldOpp.Type = 'Existing Account';
        Opportunity newOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
        newOpp.Name = 'Test';
        newOpp.Type = 'New Account';
        System.assertEquals(false, SObjectDomain.Test.Database.hasRecords());
        SObjectDomain.Test.Database.onUpdate(new Opportunity[] { newOpp }, new Map<Id, SObject> { newOpp.Id => oldOpp } );
        System.assertEquals(true, SObjectDomain.Test.Database.hasRecords());
        SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDomainConstructor.class);
        System.assertEquals(1, SObjectDomain.Errors.getAll().size());
        System.assertEquals('You cannot change the Opportunity type once it has been created.', SObjectDomain.Errors.getAll()[0].message);
        System.assertEquals(Opportunity.Type, ((SObjectDomain.FieldError)SObjectDomain.Errors.getAll()[0]).field);
    }

    @IsTest
    private static void testOnBeforeDeleteWithoutDML()
    {
        Opportunity opp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
        opp.Name = 'Test';
        opp.Type = 'Existing Account';
        System.assertEquals(false, SObjectDomain.Test.Database.hasRecords());
        SObjectDomain.Test.Database.onDelete(new Map<ID, Opportunity> { opp.Id => opp } );
        System.assertEquals(true, SObjectDomain.Test.Database.hasRecords());
        SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDomainConstructor.class);
        System.assertEquals(1, SObjectDomain.Errors.getAll().size());
        System.assertEquals('You cannot delete this Opportunity.', SObjectDomain.Errors.getAll()[0].message);
    }

    @IsTest
    private static void testOnAfterUndeleteWithoutDML()
    {
        Opportunity opp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
        opp.Name = 'Test';
        opp.Type = 'Existing Account';
        System.assertEquals(false, SObjectDomain.Test.Database.hasRecords());
        SObjectDomain.Test.Database.onUndelete(new list<Opportunity> { opp } );
        System.assertEquals(true, SObjectDomain.Test.Database.hasRecords());
        SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDomainConstructor.class);
    }

    @IsTest
    private static void testObjectSecurity()
    {
        // Create a user which will not have access to the test object type
        User testUser = createChatterExternalUser();
        if(testUser==null)
            return; // Abort the test if unable to create a user with low enough acess
        System.runAs(testUser)
        {
            // Test Create object security
            Opportunity opp = new Opportunity ( Name = 'Test', Type = 'Existing Account' );
            SObjectDomain.Test.Database.onInsert(new Opportunity[] { opp } );
            try {
                SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDomainConstructor.class);
                System.assert(false, 'Expected access denied exception');
            } catch (Exception e) {
                System.assertEquals('Permission to create an Opportunity denied.', e.getMessage());
            }

            // Test Update object security
            Opportunity existingOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
            existingOpp.Name = 'Test';
            existingOpp.Type = 'Existing Account';
            SObjectDomain.Test.Database.onUpdate(new List<Opportunity> { opp }, new Map<Id, Opportunity> { opp.Id => opp } );
            try {
                SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDomainConstructor.class);
                System.assert(false, 'Expected access denied exception');
            } catch (Exception e) {
                System.assertEquals('Permission to udpate an Opportunity denied.', e.getMessage());
            }

            // Test Delete object security
            SObjectDomain.Test.Database.onDelete(new Map<Id, Opportunity> { opp.Id => opp });
            try {
                SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDomainConstructor.class);
                System.assert(false, 'Expected access denied exception');
            } catch (Exception e) {
                System.assertEquals('Permission to delete an Opportunity denied.', e.getMessage());
            }
        }
    }

    @IsTest
    private static void testErrorLogging()
    {
        // Test static helpers for raise none domain object instance errors
        Opportunity opp = new Opportunity ( Name = 'Test', Type = 'Existing Account' );
        SObjectDomain.Errors.error('Error', opp);
        SObjectDomain.Errors.error('Error', opp, Opportunity.Type);
        System.assertEquals(2, SObjectDomain.Errors.getAll().size());
        System.assertEquals('Error', SObjectDomain.Errors.getAll()[0].message);
        System.assertEquals('Error', SObjectDomain.Errors.getAll()[1].message);
        System.assertEquals(Opportunity.Type, ((SObjectDomain.FieldError)SObjectDomain.Errors.getAll()[1]).field);
        SObjectDomain.Errors.clearAll();
        System.assertEquals(0, SObjectDomain.Errors.getAll().size());
    }

    @IsTest
    private static void testTriggerState()
    {
        Opportunity opp = new Opportunity ( Name = 'Test', Type = 'Existing Account' );
        SObjectDomain.Test.Database.onInsert(new Opportunity[] { opp } );
        SObjectDomain.triggerHandler(SObjectDomain.TestSObjectStatefulDomainConstructor.class);
        System.assertEquals(1, SObjectDomain.Errors.getAll().size());
        System.assertEquals('Error on Record Test', SObjectDomain.Errors.getAll()[0].message);
    }

    @IsTest
    private static void testRecursiveTriggerState()
    {
        Opportunity opp = new Opportunity ( Name = 'Test Recursive 1', Type = 'Existing Account' );
        SObjectDomain.Test.Database.onInsert(new Opportunity[] { opp } );
        SObjectDomain.triggerHandler(SObjectDomain.TestSObjectStatefulDomainConstructor.class);
        System.assertEquals(2, SObjectDomain.Errors.getAll().size());
        System.assertEquals('Error on Record Test Recursive 2', SObjectDomain.Errors.getAll()[0].message);
        System.assertEquals('Error on Record Test Recursive 1', SObjectDomain.Errors.getAll()[1].message);
    }

    @IsTest
    private static void testOnValidateBehaviorDefault()
    {
        Opportunity oldOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
        oldOpp.Name = 'Test Default Behaviour';
        oldOpp.Type = 'Existing Account';
        Opportunity newOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
        newOpp.Name = 'Test Default Behaviour';
        newOpp.Type = 'New Account';
        SObjectDomain.Test.Database.onUpdate(new Opportunity[] { newOpp }, new Map<Id, SObject> { newOpp.Id => oldOpp } );
        SObjectDomain.triggerHandler(SObjectDomain.TestSObjectOnValidateBehaviourConstructor.class);
    }

    @IsTest
    private static void testOnValidateBehaviorOld()
    {
        Opportunity oldOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
        oldOpp.Name = 'Test Enable Old Behaviour';
        oldOpp.Type = 'Existing Account';
        Opportunity newOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
        newOpp.Name = 'Test Enable Old Behaviour';
        newOpp.Type = 'New Account';
        SObjectDomain.Test.Database.onUpdate(new Opportunity[] { newOpp }, new Map<Id, SObject> { newOpp.Id => oldOpp } );
        try {
            SObjectDomain.triggerHandler(SObjectDomain.TestSObjectOnValidateBehaviourConstructor.class);
            System.assert(false, 'Expected exception');
        } catch (Exception e) {
            System.assertEquals('onValidate called', e.getMessage());
        }
    }

    @IsTest
    private static void testKillSwitchEnabled()
    {
        //arrange

        Trigger_Overrides__c t = new Trigger_Overrides__c(
            Name = OBJECT_NAME + '_Enabled',
            Trigger_Enabled__c = true
        );
        insert t;
        TriggerOverridesSelector tos = new TriggerOverridesSelector();

        //act
        Test.startTest();
        Boolean bypassTrigger = tos.bypassTrigger(OBJECT_NAME);
        Test.stopTest();

        //assert
        System.assert(!bypassTrigger, 'bypassTrigger should false: ' + bypassTrigger);
    }

    @IsTest
    private static void testKillSwitchDisabled()
    {
        //arrange

        Trigger_Overrides__c t = new Trigger_Overrides__c(
            Name = OBJECT_NAME + '_Enabled',
            Trigger_Enabled__c = false
        );
        insert t;
        TriggerOverridesSelector tos = new TriggerOverridesSelector();

        //act
        Test.startTest();
        Boolean bypassTrigger = tos.bypassTrigger(OBJECT_NAME);
        Test.stopTest();

        //assert
        System.assert(bypassTrigger, 'bypassTrigger should true: ' + bypassTrigger);
    }

    @IsTest
    private static void testKillSwitchRecordNotFound()
    {
        //arrange
        TriggerOverridesSelector tos = new TriggerOverridesSelector();

        //act
        Test.startTest();
        Boolean bypassTrigger = tos.bypassTrigger(OBJECT_NAME);
        Test.stopTest();

        //assert
        System.assert(!bypassTrigger, 'bypassTrigger should false: ' + bypassTrigger);
    }

    @IsTest
    private static void testMasterKillSwitch()
    {
        //arrange

        Trigger_Overrides__c t = new Trigger_Overrides__c(
            Name = 'AllTriggers_Enabled',
            Trigger_Enabled__c = true
        );
        insert t;
        TriggerOverridesSelector tos = new TriggerOverridesSelector();

        //act
        Test.startTest();
        Boolean bypassTrigger = tos.bypassTrigger(OBJECT_NAME);
        Test.stopTest();

        //assert
        System.assert(!bypassTrigger, 'bypassTrigger should false: ' + bypassTrigger);
    }

    @IsTest
    private static void testKillSwitchNull()
    {
        //arrange
        TriggerOverridesSelector tos = new TriggerOverridesSelector();

        //act
        Test.startTest();
        Boolean bypassTrigger = tos.bypassTrigger(null);
        Test.stopTest();

        //assert
        System.assert(!bypassTrigger, 'bypassTrigger should false: ' + bypassTrigger);
    }

    /**
     * Create test user
     **/
    private static User createChatterExternalUser()
    {
        // Can only proceed with test if we have a suitable profile - Chatter External license has no access to Opportunity
        List<Profile> testProfiles = [Select Id From Profile where UserLicense.Name='Chatter External' limit 1];
        if(testProfiles.size()!=1)
            return null;

        // Can only proceed with test if we can successfully insert a test user
        String testUsername = System.now().format('yyyyMMddhhmmss') + '@testorg.com';
        User testUser = new User(Alias = 'test1', Email='testuser1@testorg.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = testProfiles[0].Id, TimeZoneSidKey='America/Los_Angeles', UserName=testUsername);
        try {
            insert testUser;
        } catch (Exception e) {
            return null;
        }
        return testUser;
    }
}
/**
 * Copyright (c), FinancialForce.com, inc
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *      this list of conditions and the following disclaimer in the documentation
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors
 *      may be used to endorse or promote products derived from this software without
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/