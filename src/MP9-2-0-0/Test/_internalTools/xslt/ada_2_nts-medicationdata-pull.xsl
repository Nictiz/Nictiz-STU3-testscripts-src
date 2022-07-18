<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" xmlns:nf="http://www.nictiz.nl/functions" xmlns:f="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:util="urn:hl7:utilities" version="2.0" xmlns="" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <!--Import mp specific constants (and package for underlying imports)-->
    <xsl:import href="https://raw.githubusercontent.com/Nictiz/HL7-mappings/MP920/ada_2_fhir-r4/mp/9.2.0/payload/mp_latest_package.xsl"/>
    <xsl:import href="https://raw.githubusercontent.com/Nictiz/HL7-mappings/MP920/util/mp-functions.xsl"/>
    <xsl:output indent="yes" omit-xml-declaration="yes"/>

    <xsl:strip-space elements="*"/>

    <!--<xsl:param name="mappingsUrl4FhirFixtures" select="'file:/C:/Users/144189-ADM/Documents/Git/HL7-mappings/ada_2_fhir-r4/mp/9.2.0/raadplegen_medicatiegegevens/fhir_instance_response'"/>-->
    <xsl:param name="transactionType"/>
    <xsl:param name="inputDir"/>
    <xsl:param name="outputDir"/>
    
    <xsl:variable name="transactionTypeNormalized" select="normalize-space(lower-case($transactionType))"/>
    <xsl:variable name="inputDirNormalized" select="nf:normalize-path($inputDir)"/>
    <xsl:variable name="outputDirNormalized" select="nf:normalize-path($outputDir)"/>
    
    <xsl:variable name="bsnSystem" select="$oidMap[@oid = $oidBurgerservicenummer]/@uri"/>

    <xd:doc>
        <xd:desc>Start template. Handles some ada transactions, converts them to nts. Very specific for each transaction.</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:call-template name="util:logMessage">
            <xsl:with-param name="level" select="$logINFO"/>
            <xsl:with-param name="msg">transactionType: <xsl:value-of select="$transactionTypeNormalized"/> - inputDir: <xsl:value-of select="$inputDirNormalized"/> - outputDir: <xsl:value-of select="$outputDirNormalized"/></xsl:with-param>
        </xsl:call-template>
        
        <!-- Multiple steps of sorting:
            1. By building block
            2. By scenarioset
            3. By scenario -->
        
        <xsl:for-each-group select="collection(concat($inputDirNormalized, '?select=*.xml'))" group-by="substring-before(substring-after(./adaxml/data/beschikbaarstellen_medicatiegegevens/@id, 'mg-mp-mg-tst-'), '-Scenarioset')">
            <xsl:variable name="buildingBlockShort" select="current-grouping-key()"/>
            <xsl:for-each-group select="current-group()" group-by="replace(./adaxml/data/beschikbaarstellen_medicatiegegevens/scenario-nr/@value, '(\d+)\.?(\d*[a-z]?)\*?\s?.*', '$1')">
                <xsl:variable name="scenarioset" select="xs:integer(current-grouping-key())"/>
                <xsl:choose>
                    <xsl:when test="$scenarioset = 0 and $transactionTypeNormalized = 'retrieve'">
                        <xsl:for-each-group select="current-group()" group-by="replace(./adaxml/data/beschikbaarstellen_medicatiegegevens/scenario-nr/@value, '(\d+)\.?(\d*[a-z]?)\*?\s?.*', '$2')">
                            <xsl:call-template name="createNts">
                                <xsl:with-param name="buildingBlockShort" select="$buildingBlockShort"/>
                                <xsl:with-param name="scenarioset" select="$scenarioset"/>
                            </xsl:call-template>
                        </xsl:for-each-group>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="createNts">
                            <xsl:with-param name="buildingBlockShort" select="$buildingBlockShort"/>
                            <xsl:with-param name="scenarioset" select="$scenarioset"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each-group>
        </xsl:for-each-group>
    </xsl:template>
    
    <xsl:template name="createNts">
        <xsl:param name="buildingBlockShort"/>
        <xsl:param name="scenarioset"/>
        
        <xsl:variable name="adaInstance" select="current-group()/adaxml/data/beschikbaarstellen_medicatiegegevens"/>
        
        <xsl:variable name="buildingBlockLong">
            <xsl:choose>
                <xsl:when test="$buildingBlockShort = 'MA'">
                    <xsl:value-of select="'MedicationAgreement'"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = 'MGB'">
                    <xsl:value-of select="'MedicationUse'"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = 'TA'">
                    <xsl:value-of select="'AdministrationAgreement'"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = 'VV'">
                    <xsl:value-of select="'DispenseRequest'"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = 'MTD'">
                    <xsl:value-of select="'MedicationAdministration'"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = 'MVE'">
                    <xsl:value-of select="'MedicationDispense'"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = 'WDS'">
                    <xsl:value-of select="'VariableDosingRegimen'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message terminate="yes">Could not determine building block.</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="scenario">
            <xsl:choose>
                <xsl:when test="$scenarioset = 0 or count(current-group()) = 1">
                    <xsl:value-of select="replace($adaInstance[1]/scenario-nr/@value, '(\d+)\.(\d*[a-z]?)\*?\s?.*', '$2')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'x'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="newFilename" select="concat('mp9-',lower-case($buildingBlockShort),'-',$transactionTypeNormalized,'-',$scenarioset,'-',$scenario,'.xml')"/>
        
        <xsl:variable name="ntsScenario" as="xs:string?">
            <xsl:choose>
                <xsl:when test="$transactionTypeNormalized = ('retrieve', 'send')">client</xsl:when>
                <xsl:when test="$transactionTypeNormalized = ('serve', 'receive')">server</xsl:when>
                <xsl:otherwise>
                    <xsl:message terminate="yes">Unknown transactionType</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="ntsInclude">
            <xsl:choose>
                <xsl:when test="$transactionTypeNormalized = 'retrieve' or ($transactionTypeNormalized = 'serve' and $scenarioset = 0)">
                    <xsl:value-of select="concat('mp9-', lower-case($buildingBlockShort), '-', $transactionTypeNormalized)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('mp9-', lower-case($buildingBlockShort), '-', $transactionTypeNormalized, '-testmedication')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="matchCategoryCode">
            <xsl:choose>
                <xsl:when test="$buildingBlockShort = 'TA'">
                    <xsl:value-of select="$taCode"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = 'VV'">
                    <xsl:value-of select="$vvCode"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = 'MTD'">
                    <xsl:value-of select="$mtdCode"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = 'MA'">
                    <xsl:value-of select="$maCodeMP920"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = 'MVE'">
                    <xsl:value-of select="$mveCode"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = 'MGB'">
                    <xsl:value-of select="$mgbCode"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = 'WDS'">
                    <xsl:value-of select="$wdsCode"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="matchResource">
            <xsl:choose>
                <xsl:when test="$buildingBlockShort = ('TA', 'MVE')">
                    <xsl:value-of select="'MedicationDispense'"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = ('VV', 'MA', 'WDS')">
                    <xsl:value-of select="'MedicationRequest'"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = 'MGB'">
                    <xsl:value-of select="'MedicationStatement'"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = 'MTD'">
                    <xsl:value-of select="'MedicationAdministration'"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="additionalScenarioParams">
            <xsl:variable name="adaId" select="$adaInstance/nf:removeSpecialCharacters(@id)"/>
            <xsl:choose>
                <!--TA-->
                <xsl:when test="$adaId = 'mg-mp-mg-tst-TA-Scenarioset0-v20-0-2'">
                    <xsl:value-of select="'&amp;identifier=urn:oid:2.16.840.1.113883.2.4.3.11.999.77.422037009.1|MBH_200_QA1_TA'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-TA-Scenarioset0-v20-0-3optioneel'">
                    <xsl:value-of select="'&amp;medication.code=urn:oid:2.16.840.1.113883.2.4.4.10|3956'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-TA-Scenarioset0-v20-0-4'">
                    <xsl:value-of select="'&amp;period-of-use=ge${DATE, T, D,-21}'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-TA-Scenarioset0-v20-0-5'">
                    <xsl:value-of select="'&amp;period-of-use=lt${DATE, T, D,-22}'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-TA-Scenarioset0-v20-0-6'">
                    <xsl:value-of select="'&amp;period-of-use=ge${DATE, T, D,-21}&amp;period-of-use=le${DATE, T, D,-7}'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-TA-Scenarioset0-v20-0-7'">
                    <xsl:value-of select="'&amp;pharmaceutical-treatment-identifier=urn:oid:2.16.840.1.113883.2.4.3.11.999.77.1.1|MBH_200_QA1'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-TA-Scenarioset0-v20-0-8'">
                    <xsl:value-of select="'&amp;period-of-use=le${DATE, T, D,-110}'"/>
                </xsl:when>
                <!--VV-->
                <xsl:when test="$adaId = 'mg-mp-mg-tst-VV-Scenarioset0-v20-0-2'">
                    <xsl:value-of select="'&amp;identifier=urn:oid:2.16.840.1.113883.2.4.3.11.999.77.52711000146108.1|MBH_200_QA1_VV'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-VV-Scenarioset0-v20-0-3optioneel'">
                    <xsl:value-of select="'&amp;medication.code=urn:oid:2.16.840.1.113883.2.4.4.10|3956'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-VV-Scenarioset0-v20-0-4'">
                    <xsl:value-of select="'&amp;medicationtreatment=urn:oid:2.16.840.1.113883.2.4.3.11.999.77.1.1|MBH_200_QA1'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-VV-Scenarioset0-v20-0-5'">
                    <xsl:value-of select="'&amp;identifier=urn:oid:2.16.840.1.113883.2.4.3.11.999.77.52711000146108.1|MBH_200_QAnietaanwezig'"/>
                </xsl:when>
                <!--MTD-->
                <!--MA-->
                <xsl:when test="$adaId = 'mg-mp-mg-tst-MA-Scenarioset0-v20-0-2'">
                    <xsl:value-of select="'&amp;identifier=urn:oid:2.16.840.1.113883.2.4.3.11.999.77.16076005.1|MBH_200_QA1_MA'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-MA-Scenarioset0-v20-0-3optioneel'">
                    <xsl:value-of select="'&amp;medication.code=urn:oid:2.16.840.1.113883.2.4.4.10|3956'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-MA-Scenarioset0-v20-0-4'">
                    <xsl:value-of select="'&amp;period-of-use=ge${DATE, T, D,-21}'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-MA-Scenarioset0-v20-0-5'">
                    <xsl:value-of select="'&amp;period-of-use=lt${DATE, T, D,-22}'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-MA-Scenarioset0-v20-0-6'">
                    <xsl:value-of select="'&amp;period-of-use=ge${DATE, T, D,-21}&amp;period-of-use=le${DATE, T, D,-7}'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-MA-Scenarioset0-v20-0-7'">
                    <xsl:value-of select="'&amp;pharmaceutical-treatment-identifier=urn:oid:2.16.840.1.113883.2.4.3.11.999.77.1.1|MBH_200_QA1'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-MA-Scenarioset0-v20-0-8'">
                    <xsl:value-of select="'&amp;period-of-use=le${DATE, T, D,-110}'"/>
                </xsl:when>
                <!--MVE-->
                <xsl:when test="$adaId = 'mg-mp-mg-tst-MVE-Scenarioset0-v20-0-2'">
                    <xsl:value-of select="'&amp;identifier=urn:oid:2.16.840.1.113883.2.4.3.11.999.77.373784005.1|MBH_200_QA1_MVE'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-MVE-Scenarioset0-v20-0-3optioneel'">
                    <xsl:value-of select="'&amp;medication.code=urn:oid:2.16.840.1.113883.2.4.4.10|3956'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-MVE-Scenarioset0-v20-0-4'">
                    <xsl:value-of select="'&amp;whenhandedover=ge${DATE, T, D,-21}'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-MVE-Scenarioset0-v20-0-5'">
                    <xsl:value-of select="'&amp;whenhandedover=lt${DATE, T, D,-22}'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-MVE-Scenarioset0-v20-0-6'">
                    <xsl:value-of select="'&amp;whenhandedover=ge${DATE, T, D,-21}&amp;whenhandedover=le${DATE, T, D,-7}'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-MVE-Scenarioset0-v20-0-7'">
                    <xsl:value-of select="'&amp;pharmaceutical-treatment-identifier=urn:oid:2.16.840.1.113883.2.4.3.11.999.77.1.1|MBH_200_QA1'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-MVE-Scenarioset0-v20-0-8'">
                    <xsl:value-of select="'&amp;whenhandedover=le${DATE, T, D,-110}'"/>
                </xsl:when>
                <!--MGB-->
                <xsl:when test="$adaId = 'mg-mp-mg-tst-MGB-Scenarioset0-v20-0-2'">
                    <xsl:value-of select="'&amp;identifier=urn:oid:2.16.840.1.113883.2.4.3.11.999.77.6.1|MBH_200_QA1_MGB'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-MGB-Scenarioset0-v20-0-3optioneel'">
                    <xsl:value-of select="'&amp;medication.code=urn:oid:2.16.840.1.113883.2.4.4.10|3956'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-MGB-Scenarioset0-v20-0-4'">
                    <xsl:value-of select="'&amp;period-of-use=ge${DATE, T, D,-21}'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-MGB-Scenarioset0-v20-0-5'">
                    <xsl:value-of select="'&amp;period-of-use=lt${DATE, T, D,-22}'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-MGB-Scenarioset0-v20-0-6'">
                    <xsl:value-of select="'&amp;period-of-use=ge${DATE, T, D,-21}&amp;period-of-use=le${DATE, T, D,-7}'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-MGB-Scenarioset0-v20-0-7'">
                    <xsl:value-of select="'&amp;pharmaceutical-treatment-identifier=urn:oid:2.16.840.1.113883.2.4.3.11.999.77.1.1|MBH_200_QA1'"/>
                </xsl:when>
                <xsl:when test="$adaId = 'mg-mp-mg-tst-MGB-Scenarioset0-v20-0-8'">
                    <xsl:value-of select="'&amp;period-of-use=le${DATE, T, D,-110}'"/>
                </xsl:when>
                <!--WDS-->
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="patientId" select="nf:removeSpecialCharacters($adaInstance[1]/patient/naamgegevens/concat(initialen/@value,geslachtsnaam/achternaam/@value))"/>
        <xsl:variable name="patientBsn" select="$adaInstance[1]/patient/identificatienummer/@value"/>
        
        <xsl:variable name="returnCount" select="count($adaInstance/medicamenteuze_behandeling/*[not(local-name() = 'identificatie')])"/>
        <xsl:variable name="returnMedicationCount" select="count($adaInstance/bouwstenen/farmaceutisch_product)"/>
        <xsl:variable name="returnEntryCount" select="$returnCount + $returnMedicationCount"/>
        <xsl:variable name="returnEntryBreakdown" select="concat('(Consists of ', $returnCount, ' ', $matchResource, ' and ', $returnMedicationCount, ' Medication resources.)')"/>
        
        <xsl:variable name="description">
            <xsl:choose>
                <xsl:when test="count(current-group()) gt 1">
                    <xsl:variable name="in1" select="nf:normalize-description($adaInstance[1]/@desc)"/>
                    <xsl:variable name="in2" select="nf:normalize-description($adaInstance[2]/@desc)"/>
                    
                    <xsl:variable name="compare12" select="nf:compare-strings($in1, $in2, 1)"/>
                    <xsl:choose>
                        <xsl:when test="string-length(nf:normalize-description($adaInstance[3]/@desc)) gt 0">
                            <xsl:value-of select="nf:compare-strings($compare12, nf:normalize-description($adaInstance[3]/@desc), 1)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$compare12"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="in" select="$adaInstance/@desc"/>
                    <xsl:value-of select="nf:normalize-description($in)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- Some hard-coded exclusions, until we think of somethinig smarter to exclude these files -->
        <xsl:choose>
            <xsl:when test="$buildingBlockShort = 'MA' and $scenarioset = (4, 5, 8, 9, 11, 13)
                or $buildingBlockShort = 'TA' and $scenarioset = (4, 5, 8, 9, 11)
                or $buildingBlockShort = 'VV' and $scenarioset = (3, 4, 5, 6, 11, 13)
                or $buildingBlockShort = 'MTD' and $scenarioset = 13
                or $buildingBlockShort = 'MVE' and $scenarioset = (3, 4, 5, 6, 8, 11)">
                <xsl:message>Scenario <xsl:value-of select="$buildingBlockShort"/>-<xsl:value-of select="$scenarioset"/>-<xsl:value-of select="$scenario"/> excluded from output</xsl:message>
            </xsl:when>
            <xsl:otherwise>
                <xsl:result-document href="{concat($outputDirNormalized,nf:first-cap($transactionTypeNormalized),'/',$buildingBlockLong,'/',$newFilename)}">
                    <TestScript xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" nts:scenario="{$ntsScenario}">
                        <nts:include value="{$ntsInclude}">
                            <nts:with-parameter name="scenarioset" value="{$scenarioset}"/>
                            <nts:with-parameter name="scenario" value="{$scenario}"/>
                            <nts:with-parameter name="scenarioDescription" value="{$description}"/>
                            <nts:with-parameter name="scenarioPatient" value="{$patientId}"/>
                            <xsl:choose>
                                <xsl:when test="$buildingBlockShort = ('TA', 'MA', 'MVE', 'MGB') and $adaInstance/scenario-nr/@value = ('0.4', '0.5', '0.6', '0.8')">
                                    <nts:with-parameter name="scenarioDateT" value="yes"/>
                                </xsl:when>
                            </xsl:choose>
                            <nts:with-parameter name="scenarioParams" value="?patient.identifier={$bsnSystem}|{$patientBsn}&amp;category=http://snomed.info/sct|{$matchCategoryCode}{$additionalScenarioParams}&amp;_include={$matchResource}:medication"/>
                            <nts:with-parameter name="returnCount" value="{$returnCount}"/>
                            <nts:with-parameter name="returnEntryCount" value="{$returnEntryCount}"/>
                            <xsl:choose>
                                <xsl:when test="$returnEntryCount gt 0">
                                    <nts:with-parameter name="returnEntryBreakdown" value="{$returnEntryBreakdown}"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <nts:with-parameter name="returnEntryBreakdown" value="(Consists of no resources.)"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </nts:include>
                    </TestScript>
                </xsl:result-document>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Capitalize first letter of a string</xd:desc>
        <xd:param name="in">The string to be handled</xd:param>
    </xd:doc>
    <xsl:function name="nf:first-cap" as="xs:string?">
        <xsl:param name="in" as="xs:string?"/>
        <xsl:sequence select="concat(upper-case(substring($in, 1, 1)), substring($in, 2))"/>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>Normalize a filepath</xd:desc>
        <xd:param name="in">The string to be handled</xd:param>
    </xd:doc>
    <xsl:function name="nf:normalize-path" as="xs:string?">
        <xsl:param name="in" as="xs:string?"/>
        <xsl:variable name="fixSlashes" select="replace($in,'\\','/')"/>
        <xsl:variable name="filePrefix">
            <xsl:choose>
                <xsl:when test="starts-with($fixSlashes, 'file:/')">
                    <xsl:value-of select="$fixSlashes"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('file:/', $fixSlashes)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="trailingSlash">
            <xsl:choose>
                <xsl:when test="ends-with($filePrefix, '/')">
                    <xsl:value-of select="$filePrefix"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($filePrefix, '/')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$trailingSlash"/>
    </xsl:function>
    
    <xsl:function name="nf:normalize-description" as="xs:string?">
        <xsl:param name="in" as="xs:string?"/>
        
        <xsl:variable name="replaceNewline" select="replace($in, '&#xA;', ' ')"/>
        <xsl:variable name="removeTags" select="replace($replaceNewline, '(&lt;.+?&gt;)', '')"/>
        <xsl:variable name="removeId">
            <xsl:choose>
                <xsl:when test="$transactionTypeNormalized = 'retrieve'">
                    <xsl:variable name="removeString1" select="replace($removeTags, ' \(in kwalificatiesimulator het id van &#34;(.+?)&#34; invoeren\)', '')"/>
                    <xsl:variable name="removeString2" select="replace($removeString1, ' \(filter op een niet in het systeem aanwezige id &#34;(.+?)&#34;\)', '')"/>
                    <xsl:value-of select="$removeString2"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$removeTags"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$removeId"/>
    </xsl:function>
    
    <xsl:function name="nf:compare-strings" as="xs:string?">
        <xsl:param name="in1" as="xs:string?"/>
        <xsl:param name="in2" as="xs:string?"/>
        <xsl:param name="i" as="xs:integer"/>
        
        <xsl:choose>
            <xsl:when test="$i gt string-length($in1)">
                <xsl:value-of select="$in1"/>
            </xsl:when>
            <xsl:when test="substring($in1, $i, 1) = substring($in2, $i, 1)">
                <xsl:value-of select="nf:compare-strings($in1, $in2, $i + 1)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="substring($in1, 1, $i - 1)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

</xsl:stylesheet>
