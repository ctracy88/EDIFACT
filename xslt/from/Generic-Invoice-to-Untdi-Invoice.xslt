<?xml version="1.0"?>
<!--
	XSLT to transform a Genric XML Invoice into a version 8 or 9 UNTDI Invoice.
	
	Input: Generic XML Invoice.
	Output: Tradacoms version 8 or 9 Invoice.
	
	Author: Pete Shelmerdine
	Version: 1.0
	Creation Date: 20-Feb-2006
	
	Last Modified Date: 23-Feb-2006
	Last Modified By: Pete Shelmerdine	
-->
<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:date="com.css.base.xml.xslt.ext.XsltDateExtension"
                xmlns:math="com.css.base.xml.xslt.ext.XsltMathExtension"
                xmlns:str="com.css.base.xml.xslt.ext.XsltStringExtension"
                xmlns:untdi="com.css.base.xml.xslt.ext.edi.XsltParsedUntdiEdiExtension"
								xmlns:mapper="com.api.tx.MapperEngine"
                extension-element-prefixes="date mapper untdi math str">

    <xsl:output method="xml"/>

		<!-- Useful information about Hub specifics -->
	  <xsl:param name="HubInfo"/>
	  <!-- Set to true if not to automatically generate generation numbers -->
	  <xsl:param name="UseGivenGenNumbers"/>	  
	  <!-- Ignore the Discount Percentage being output if this is 'true' -->
	  <xsl:param name="IgnoreDSCP"/>
	  <!-- Set to true if to narrow down the FIL number to vendor code level -->
	  <xsl:param name="UseVendorCodeInGenNumbers"/>	  
	  <!-- Set this to true if to output the VAT number as a DNA GNAR too (Unimer do this when a foriegn supplier) -->
	  <xsl:param name="PutVatIntoDNA"/>	  
	  <!-- If set to true then the EDI will apear as one long line. This param is optional. -->
	  <xsl:param name="ForceWrapped"/>	  
	  <!-- Force a version, 8 or 9 for hubs that support more than one version -->
	  <xsl:param name="Version"/>
	  <!-- Optional if using GXS or TGMS then a network password is needed -->
	  <xsl:param name="NetworkPassword"/>
	  <!-- Optional if want some validation done on the line totals -->
	  <xsl:param name="CheckLineTotals"/>
	<!-- Set to true to get CDT EAN from generic input (this hasn't been the case -->
	<xsl:param name="CdtEanFromInput"/>
	<!-- Use these to override the SDT and STX sender ANAs -->
	<xsl:param name="SupplierAnaCode"/>
	<xsl:param name="SenderAnaCode"/>
	<!-- This can be used to modify the SNRF -->
	<xsl:param name="InterchangeNumberPrefix"/>
	<!-- This can be used to offset the FIL number -->
	<xsl:param name="FILOffset"/>
	<!-- Can use this to force a particular hub ID to be used -->
	  <xsl:param name="HubID"/>
	<!-- Can be used to force two decimal places on line calculations rather than the default of 4 -->
	<xsl:param name="ForceTwoDecPlaces"/>

    <xsl:template match="/">
    
			<mapper:logMessage>
				Transforming to UNTDI EDI INVOICE
			</mapper:logMessage>
    
			<Document type="UNTDI">
				<xsl:attribute name="wrapped">
					<xsl:choose>
						<xsl:when test="$ForceWrapped = 'true'">true</xsl:when>
						<xsl:when test="$ForceWrapped = 'TRUE'">true</xsl:when>
						<xsl:otherwise>false</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
			
				<!-- Load the hub info XML document -->
				<xsl:variable name="hubs" select="document($HubInfo)"/>
				
				<!-- This is the STX ANA to which this document is intended -->
				<xsl:variable name="hubID" select="/Batch/Invoice[1]/BatchReferences/ReceiverCode"/>
				
				<!-- Some hubs specify different criterea in test and live modes -->
				<xsl:variable name="testMode" select="/Batch/Invoice[1]/BatchReferences/@test"/>

				<!-- Look-up the hub envelope record within the loaded list -->
				<xsl:variable name="hubEnvelope" select="$hubs/Hubs/Hub/Envelope[@ean = $hubID][@test = $testMode][@syntax = 'ANA' or @syntax = 'ANAA'] | $hubs/Hubs/Hub[@id = $HubID]/Envelope[@test = $testMode]"/>

				<xsl:if test="not($hubEnvelope)">
					<mapper:logError>
						Cannot determine Tradacoms Hub from STX Receiver EAN: <xsl:value-of select="$hubID"/>, mode: <xsl:value-of select="$testMode"/>
					</mapper:logError>
				</xsl:if>

				<xsl:variable name="version">
					<xsl:choose>
						<xsl:when test="$Version = '8'">8</xsl:when>
						<xsl:otherwise>9</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>

				<!-- get the particular document we are after within the hub record -->
				<xsl:variable name="hubDocument" select="$hubEnvelope/Document[@id = 'INVOICE'][@ver = $version]"/>

				<xsl:if test="not($hubDocument)">
					<mapper:logError>
						Cannot locate document type INVOICE for Receiver EAN: <xsl:value-of select="$hubID"/>, mode: <xsl:value-of select="$testMode"/>, version: <xsl:value-of select="$version"/>
					</mapper:logError>
				</xsl:if>
			
				<!-- Create a FIL generation number which we'll use in the STX SNRF too -->
				<xsl:variable name="GenNumber">
					<xsl:choose>
						<xsl:when test="$UseGivenGenNumbers = 'true'">
							<xsl:value-of select="/Batch/Invoice[1]/BatchReferences/Number"/>
						</xsl:when>
						<xsl:when test="$UseVendorCodeInGenNumbers = 'true'">
							<!-- create a finer level one -->
							<mapper:genNum max="9999">
								<xsl:value-of select="concat(/Batch/Invoice[1]/BatchReferences/SenderCode, '.', /Batch/Invoice[1]/Supplier/CustomersCode, '.', $hubEnvelope/@ean, '.', $hubDocument/@app)"/>
							</mapper:genNum>
						</xsl:when>
						<xsl:when test="string-length($InterchangeNumberPrefix) &gt; 0">
							<mapper:genNum max="9999">
								<xsl:value-of select="concat($InterchangeNumberPrefix, '.', /Batch/Invoice[1]/BatchReferences/SenderCode, '.', $hubEnvelope/@ean, '.', $hubDocument/@app)"/>
							</mapper:genNum>
						</xsl:when>
						<xsl:otherwise>
							<!-- create one -->
							<mapper:genNum max="9999">
								<xsl:value-of select="concat(/Batch/Invoice[1]/BatchReferences/SenderCode, '.', $hubEnvelope/@ean, '.', $hubDocument/@app)"/>
							</mapper:genNum>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>

				<mapper:logMessage>
					Processing invoices for: <xsl:value-of select="$hubEnvelope/../@id"/>
				</mapper:logMessage>

				<mapper:logDetail>
					<b><xsl:value-of select="$hubEnvelope/../@id"/></b> File Generation number: <xsl:value-of select="$GenNumber"/>
				</mapper:logDetail>
				
				<!-- Store in case we need it post mapping, filename generation, etc -->							
				<mapper:setVar name="GenNumber">
					<xsl:value-of select="$GenNumber"/>
				</mapper:setVar>
			
				<STX>
					<!-- Process the envelope information -->
					<xsl:call-template name="write-stx-content">
						<xsl:with-param name="batchReferences" select="Batch/Invoice[1]/BatchReferences"/>
						<xsl:with-param name="hubEnvelope" select="$hubEnvelope"/>
						<xsl:with-param name="hubDocument" select="$hubDocument"/>
						<xsl:with-param name="genNumber" select="$GenNumber"/>
					</xsl:call-template>

					<!-- Invoice Header. All headers are assumed to be the same within a batch destined for UNTDI -->
					<mapper:setVar name="segmentCount">0</mapper:setVar>
					<mapper:setVar name="messageCount">0</mapper:setVar>
					<MHD>
						<mapper:incVar name="segmentCount"/>
						<mapper:incVar name="messageCount"/>

						<Field> <!-- Message Ref -->
							<mapper:getVar name="messageCount"/>
						</Field>
						<Field> <!-- Version 8 or 9 invoice -->
							<Field>INVFIL</Field>
							<Field>
								<xsl:choose>
									<xsl:when test="$hubDocument/@ver = '9'">9</xsl:when>
									<xsl:when test="$hubDocument/@ver = '8'">6</xsl:when>
									<xsl:otherwise>9</xsl:otherwise>
								</xsl:choose>
							</Field>
						</Field>

						<TYP>
							<mapper:incVar name="segmentCount"/>
							<Field>0700</Field>
							<Field>
								<xsl:choose>
									<!-- <xsl:when test="$hubEnvelope/@ean = '5023949000004'">INVOIC</xsl:when> --> <!-- JLP are gay (no longer) -->
									<xsl:otherwise>INVOICES</xsl:otherwise> <!-- everyone else straight -->
								</xsl:choose>							
							</Field>
						</TYP>
						
						<!-- Sender Details -->
						<SDT>
							<mapper:incVar name="segmentCount"/>
							<Field> <!-- Codes -->
								<Field tag="SDT-EAN" maxLen="13"> <!-- EAN -->
									<xsl:choose>
										<xsl:when test="string-length($SupplierAnaCode) &gt; 0"><xsl:value-of select="$SupplierAnaCode"/></xsl:when>
										<xsl:otherwise><xsl:value-of select="Batch/Invoice[1]/Supplier/EanCode"/></xsl:otherwise>
									</xsl:choose>									
								</Field> 
								<Field tag="SDT-CustomersCode" maxLen="17"><xsl:value-of select="Batch/Invoice[1]/Supplier/CustomersCode"/></Field> <!-- Allocated by Customer -->
							</Field>
							<Field maxLen="40"><xsl:value-of select="Batch/Invoice[1]/Supplier/Name"/></Field> <!-- Name -->
							<Field> <!-- Address -->
								<Field tag="SDT-Add1" maxLen="35"><xsl:value-of select="substring(Batch/Invoice[1]/Supplier/Address/Title, 1, 35)"/></Field>					
								<Field tag="SDT-Add2" maxLen="35"><xsl:value-of select="substring(Batch/Invoice[1]/Supplier/Address/Street, 1, 35)"/></Field>					
								<Field tag="SDT-Add3" maxLen="35"><xsl:value-of select="substring(Batch/Invoice[1]/Supplier/Address/Town, 1, 35)"/></Field>					
								<Field tag="SDT-Add4" maxLen="35"><xsl:value-of select="substring(Batch/Invoice[1]/Supplier/Address/City, 1, 35)"/></Field>					
								<Field tag="SDT-Add5" maxLen="8"><xsl:value-of select="substring(Batch/Invoice[1]/Supplier/Address/PostCode, 1, 8)"/></Field>					
							</Field>
							<Field>
								<xsl:choose>
									<!-- Kerry Foods and Breeo want both VAT slots filled out -->
									<xsl:when test="$hubID = '5099104000792' or $hubID = '5011069000006'">
										<Field maxLen="9" type="integer" tag="SDT VAT"><xsl:value-of select="Batch/Invoice[1]/Supplier/VatNumber[@type = 'Numeric']"/></Field> <!-- Numeric VAT number (UK) -->
										<Field maxLen="17" tag="SDT VAT"><xsl:value-of select="Batch/Invoice[1]/Supplier/VatNumber[@type = 'Alpha']"/></Field> <!-- Alpha-Numeric VAT number (UK) -->
									</xsl:when>
									<xsl:when test="Batch/Invoice[1]/Supplier/VatNumber/@type = 'Numeric'">
										<Field maxLen="9" type="integer" tag="SDT VAT"><xsl:value-of select="Batch/Invoice[1]/Supplier/VatNumber[@type = 'Numeric']"/></Field> <!-- Numeric VAT number (UK) -->
										<Field/>
									</xsl:when>
									<xsl:when test="Batch/Invoice[1]/Supplier/VatNumber/@type = 'Alpha'">
										<Field/>
										<Field maxLen="17" tag="SDT VAT"><xsl:value-of select="Batch/Invoice[1]/Supplier/VatNumber[@type = 'Alpha']"/></Field> <!-- Numeric VAT number (UK) -->
									</xsl:when>
									<xsl:when test="math:isNum(Batch/Invoice[1]/Supplier/VatNumber)">
										<Field maxLen="9" type="integer" tag="SDT VAT"><xsl:value-of select="str:last(Batch/Invoice[1]/Supplier/VatNumber, 9)"/></Field> <!-- Numeric VAT number (UK) -->
										<Field/>
									</xsl:when>
									<xsl:otherwise>
										<Field/>
										<Field maxLen="17" tag="SDT VAT"><xsl:value-of select="Batch/Invoice[1]/Supplier/VatNumber"/></Field> <!-- Alpha VAT number (UK) -->
									</xsl:otherwise>
								</xsl:choose>							
							</Field>				
						</SDT>				

						<!-- Customer Details -->
						<CDT>
							<mapper:incVar name="segmentCount"/>
							<Field> <!-- Codes -->
								<Field tag="CDT-Ean" maxLen="13">
									<xsl:choose>
										<xsl:when test="$CdtEanFromInput = 'true'">
											<xsl:value-of select="Batch/Invoice[1]/Customer/EanCode"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="$hubDocument/@ean"/>
										<!--	<xsl:if test="not($hubDocument/@ean = Batch/Invoice[1]/Customer/EanCode)">
												<mapper:logWarning>CDT EAN from hubs file (<xsl:value-of select="$hubDocument/@ean"/>) doesn't match customer EAN in source (<xsl:value-of select="Batch/Invoice[1]/Customer/EanCode"/>)</mapper:logWarning>
											</xsl:if> -->
										</xsl:otherwise>
									</xsl:choose>
								</Field> <!-- EAN -->
								<Field tag="CDT-SuppliersCode" maxLen="17" normalise="false">
									<xsl:value-of select="Batch/Invoice[1]/Customer/SuppliersCode"/>
								</Field> <!-- Allocated by Supplier -->
							</Field>
							<Field maxLen="40"><xsl:value-of select="Batch/Invoice[1]/Customer/Name"/></Field> <!-- Name -->
							<Field> <!-- Address -->
								<Field tag="CDT-Add1" maxLen="35"><xsl:value-of select="substring(Batch/Invoice[1]/Customer/Address/Title, 1, 35)"/></Field>					
								<Field tag="CDT-Add2" maxLen="35"><xsl:value-of select="substring(Batch/Invoice[1]/Customer/Address/Street, 1, 35)"/></Field>					
								<Field tag="CDT-Add3" maxLen="35"><xsl:value-of select="substring(Batch/Invoice[1]/Customer/Address/Town, 1, 35)"/></Field>					
								<Field tag="CDT-Add4" maxLen="35"><xsl:value-of select="substring(Batch/Invoice[1]/Customer/Address/City, 1, 35)"/></Field>					
								<Field tag="CDT-Add5" maxLen="8"><xsl:value-of select="substring(Batch/Invoice[1]/Customer/Address/PostCode, 1, 8)"/></Field>					
							</Field>
							<Field>
								<xsl:choose>
									<xsl:when test="Batch/Invoice[1]/Customer/VatNumber/@type = 'Numeric'">
										<Field maxLen="9" type="integer" tag="CDT VAT"><xsl:value-of select="Batch/Invoice[1]/Customer/VatNumber[@type = 'Numeric']"/></Field>	<!-- Numeric VAT number (UK) -->
										<Field/>
									</xsl:when>
									<xsl:when test="Batch/Invoice[1]/Customer/VatNumber/@type = 'Alpha'">
										<Field/>
										<Field maxLen="17" tag="CDT VAT"><xsl:value-of select="Batch/Invoice[1]/Customer/VatNumber[@type = 'Alpha']"/></Field>	<!-- Numeric VAT number (UK) -->
									</xsl:when>
									<xsl:when test="string-length(Batch/Invoice[1]/Customer/VatNumber) &gt; 0 and math:isNum(Batch/Invoice[1]/Customer/VatNumber)">
										<Field maxLen="9" type="integer" tag="CDT VAT"><xsl:value-of select="Batch/Invoice[1]/Customer/VatNumber"/></Field>
										<Field/>
									</xsl:when>
									<xsl:when test="string-length(Batch/Invoice[1]/Customer/VatNumber) = 9">
										<Field maxLen="9" type="integer" tag="CDT VAT"><xsl:value-of select="Batch/Invoice[1]/Customer/VatNumber"/></Field>	<!-- Numeric VAT number (UK) -->
										<Field/>
									</xsl:when>
									<xsl:otherwise>
										<Field/>
										<Field maxLen="17" tag="CDT VAT"><xsl:value-of select="$hubDocument/@vat"/></Field>
									</xsl:otherwise>
								</xsl:choose>
							</Field>
						</CDT>				

						<mapper:setVar name="dnaCounter">0</mapper:setVar>

						<xsl:if test="string-length(Batch/Invoice[1]/@currency) &gt; 0">
							<DNA>
								<mapper:incVar name="segmentCount"/>
								<mapper:incVar name="dnaCounter"/>
								<Field><mapper:getVar name="dnaCounter"/></Field> <!-- Sequence -->
								<Field/> <!-- DNAC -->
								<Field> <!-- RTEX -->
									<Field>073</Field> <!-- 073 = currency -->
									<Field><xsl:value-of select="Batch/Invoice[1]/@currency"/></Field>
								</Field>
								<Field/> <!-- GNAR -->
							</DNA>
						</xsl:if>						

						<xsl:if test="string-length(Batch/Invoice[1]/Supplier/FreeText) &gt; 0">
							<DNA>
								<mapper:incVar name="segmentCount"/>
								<mapper:incVar name="dnaCounter"/>
								<Field><mapper:getVar name="dnaCounter"/></Field> <!-- Sequence -->
								<Field/> <!-- DNAC -->
								<Field/> <!-- RTEX -->
								<Field> <!-- GNAR -->
									<Field><xsl:value-of select="substring(Batch/Invoice[1]/Supplier/FreeText, 1, 40)"/></Field>
								</Field>
							</DNA>
						</xsl:if>						

						<FIL>
							<mapper:incVar name="segmentCount"/>
							<Field> <!-- File generation number -->
								<xsl:choose>
									<xsl:when test="math:isNum($FILOffset)"><xsl:value-of select="$GenNumber + math:toNum($FILOffset)"/></xsl:when>
									<xsl:otherwise><xsl:value-of select="$GenNumber"/></xsl:otherwise>
								</xsl:choose>								
							</Field>
							<Field> <!-- version -->
								<xsl:value-of select="'1'"/>
							</Field>
							<Field> <!-- Generation date -->
								<xsl:choose>
									<xsl:when test="string-length(Batch/Invoice[1]/BatchReferences/Date) &gt; 0">
										<date:reformat curFormat="yyyy-MM-dd" newFormat="yyMMdd">
											<xsl:value-of select="Batch/Invoice[1]/BatchReferences/Date"/>
										</date:reformat>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="date:insert('yyMMdd')"/>
									</xsl:otherwise>
								</xsl:choose>
							</Field>
						</FIL>
						
						<xsl:if test="string-length(Batch/Invoice[1]/InvoiceExpiresDate) &gt; 0 or string-length(Batch/Invoice[1]/DeliveryDate) &gt; 0">
							<FDT>
								<mapper:incVar name="segmentCount"/>
								<Field> <!-- Invoice Period end Date -->
									<xsl:choose>
										<xsl:when test="string-length(Batch/Invoice[1]/InvoiceExpiresDate)">
											<date:reformat curFormat="yyyy-MM-dd" newFormat="yyMMdd">
												<xsl:value-of select="Batch/Invoice[1]/InvoiceExpiresDate"/>
											</date:reformat>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="date:insert('yyMMdd')"/>
										</xsl:otherwise>
									</xsl:choose>
								</Field>				
								<Field> <!-- Delivery Period End Date -->
									<xsl:choose>
										<xsl:when test="string-length(Batch/Invoice[1]/DeliveryDate)">
											<date:reformat curFormat="yyyy-MM-dd" newFormat="yyMMdd">
												<xsl:value-of select="Batch/Invoice[1]/DeliveryDate"/>
											</date:reformat>
										</xsl:when>
										<xsl:otherwise>
											<date:reformat curFormat="yyyy-MM-dd" newFormat="yyMMdd">
												<xsl:value-of select="Batch/Invoice[1]/InvoiceExpiresDate"/>
											</date:reformat>
										</xsl:otherwise>
									</xsl:choose>
								</Field>
							</FDT>
						</xsl:if>

						<!-- Location from where the invoice was raised -->
						<xsl:if test="string-length(Batch/Invoice[1]/InvoiceGenerationLocation) &gt; 0">
							<ACD>
								<mapper:incVar name="segmentCount"/>
								<Field> <!-- Invoice system location details -->
									<xsl:if test="string-length(InvoiceGenerationLocation) = 13">
										<Field maxLen="13"><xsl:value-of select="Batch/Invoice[1]/InvoiceGenerationLocation"/></Field> <!-- EAN -->
										<Field/> <!-- Supplier's own code -->
									</xsl:if>
									<xsl:if test="string-length(InvoiceGenerationLocation) != 13">
										<Field/> <!-- EAN -->
										<Field tag="ACD-Location" maxLen="17"><xsl:value-of select="Batch/Invoice[1]/InvoiceGenerationLocation"/></Field> <!-- Supplier's own code -->
									</xsl:if>
								</Field>
							</ACD>
						</xsl:if>
						
						<MTR>
							<mapper:incVar name="segmentCount"/>
							<Field>
								<mapper:getVar name="segmentCount"/>
							</Field>
						</MTR>
										
						<!-- Process each invoice in the batch -->
						<xsl:apply-templates select="Batch/Invoice">
							<xsl:with-param name="hubEnvelope" select="$hubEnvelope"/>
							<xsl:with-param name="hubDocument" select="$hubDocument"/>
						</xsl:apply-templates>
		      
					</MHD>
						
					<mapper:setVar name="segmentCount">0</mapper:setVar>		
					<MHD>
						<mapper:incVar name="messageCount"/>
						<mapper:incVar name="segmentCount"/>
						<Field>
							<mapper:getVar name="messageCount"/>
						</Field>
						<!-- Message type -->
						<Field>
							<Field>VATTLR</Field>
							<Field>
								<xsl:choose>
									<xsl:when test="$hubDocument/@ver = '9'">9</xsl:when>
									<xsl:when test="$hubDocument/@ver = '8'">6</xsl:when>
									<xsl:otherwise>9</xsl:otherwise>
								</xsl:choose>
							</Field>
						</Field>

						<!-- Write out each batch VAT summary -->
						<mapper:setVar name="stlCount">0</mapper:setVar>
						<xsl:call-template name="BatchVatSummary">
							<xsl:with-param name="summaries" select="/Batch/Invoice/VatSummary[VatCode = 'S'][VatPercentage = 17.5]"/>
						</xsl:call-template>
						<xsl:call-template name="BatchVatSummary">
							<xsl:with-param name="summaries" select="/Batch/Invoice/VatSummary[VatCode = 'S'][VatPercentage = 15]"/>
						</xsl:call-template>
						<xsl:call-template name="BatchVatSummary">
							<xsl:with-param name="summaries" select="/Batch/Invoice/VatSummary[VatCode = 'S'][VatPercentage = 21.5]"/>
						</xsl:call-template>
						<xsl:call-template name="BatchVatSummary">
							<xsl:with-param name="summaries" select="/Batch/Invoice/VatSummary[VatCode = 'S'][VatPercentage = 23]"/>
						</xsl:call-template>
						<xsl:call-template name="BatchVatSummary">
							<xsl:with-param name="summaries" select="/Batch/Invoice/VatSummary[VatCode = 'S'][VatPercentage = 21]"/>
						</xsl:call-template>
						<xsl:call-template name="BatchVatSummary">
							<xsl:with-param name="summaries" select="/Batch/Invoice/VatSummary[VatCode = 'S'][VatPercentage = 20]"/>
						</xsl:call-template>
						<xsl:call-template name="BatchVatSummary">
							<xsl:with-param name="summaries" select="/Batch/Invoice/VatSummary[VatCode = 'S'][VatPercentage = 13.5]"/>
						</xsl:call-template>
						<xsl:call-template name="BatchVatSummary">
							<xsl:with-param name="summaries" select="/Batch/Invoice/VatSummary[VatCode = 'Z']"/>
						</xsl:call-template>
						<xsl:call-template name="BatchVatSummary">
							<xsl:with-param name="summaries" select="/Batch/Invoice/VatSummary[VatCode = 'E']"/>
						</xsl:call-template>
						<xsl:call-template name="BatchVatSummary">
							<xsl:with-param name="summaries" select="/Batch/Invoice/VatSummary[VatCode = 'L']"/>
						</xsl:call-template>
						<xsl:call-template name="BatchVatSummary">
							<xsl:with-param name="summaries" select="/Batch/Invoice/VatSummary[VatCode = 'H']"/>
						</xsl:call-template>
						<xsl:call-template name="BatchVatSummary">
							<xsl:with-param name="summaries" select="/Batch/Invoice/VatSummary[VatCode = 'X']"/>
						</xsl:call-template>
						
						<MTR>
							<mapper:incVar name="segmentCount"/>
							<Field>
								<mapper:getVar name="segmentCount"/>
							</Field>
						</MTR>			
					</MHD>
					
					<!-- Invoice batch summary -->
					<mapper:setVar name="segmentCount">0</mapper:setVar>		
					<MHD>
						<mapper:incVar name="messageCount"/>
						<mapper:incVar name="segmentCount"/>
						<Field>
							<mapper:getVar name="messageCount"/>
						</Field>
						<!-- Message type -->
						<Field>
							<Field>INVTLR</Field>
							<Field>
								<xsl:if test="$hubDocument/@ver = '9'">9</xsl:if>
								<xsl:if test="$hubDocument/@ver = '8'">5</xsl:if>
							</Field>
						</Field>
					
						<TOT>
							<mapper:incVar name="segmentCount"/>
							<!-- Total after discounts and charges without settlement discount and VAT -->
							<Field type="integer" tag="FASE"><xsl:value-of select="untdi:convertToUntdiDecimal(sum(Batch/Invoice/InvoiceSummary/Total2), 2)"/></Field> <!-- FASE -->
							<!-- Total after discounts and charges with settlement discount -->
							<Field type="integer" tag="FASI"><xsl:value-of select="untdi:convertToUntdiDecimal(sum(Batch/Invoice/InvoiceSummary/Total3), 2)"/></Field> <!-- FASI -->
							<!-- Total VAT -->
							<Field type="integer" tag="FVAT"><xsl:value-of select="untdi:convertToUntdiDecimal(sum(Batch/Invoice/InvoiceSummary/VatAmount), 2)"/></Field> <!-- FVAT -->
							<!-- Total after discounts and charges without settlement discount applied + VAT -->
							<Field type="integer" tag="FPSE"><xsl:value-of select="untdi:convertToUntdiDecimal(sum(Batch/Invoice/InvoiceSummary/Total4), 2)"/></Field> <!-- FPSE -->
							<!-- Total after discounts and charges with settlement discount applied + VAT -->
							<Field type="integer" tag="FPSI"><xsl:value-of select="untdi:convertToUntdiDecimal(sum(Batch/Invoice/InvoiceSummary/Total5), 2)"/></Field> <!-- FPSI -->
							<Field type="integer"><xsl:value-of select="count(Batch/Invoice)"/></Field> <!-- Total number of invoices -->
						</TOT>
						<MTR>
							<mapper:incVar name="segmentCount"/>
							<Field>
								<mapper:getVar name="segmentCount"/>
							</Field>
						</MTR>			
					</MHD>
					
					<xsl:if test="$hubDocument/@rsg &gt; 0">
						<!-- Reconcilliation message -->
						<mapper:setVar name="segmentCount">0</mapper:setVar>
						<MHD>
							<mapper:incVar name="messageCount"/>
							<mapper:incVar name="segmentCount"/>
							<Field>
								<mapper:getVar name="messageCount"/>
							</Field>
							<!-- Message type -->
							<Field>
								<Field>RSGRSG</Field>
								<Field minLen="1" maxLen="1" type="integer"  tag="RSGVER">
									<xsl:value-of select="$hubDocument/@rsg"/>
								</Field>
							</Field>
						
							<RSG>
								<mapper:incVar name="segmentCount"/>
								<Field><xsl:value-of select="$GenNumber"/></Field> <!-- STX reference number -->
								<Field><xsl:value-of select="$hubEnvelope/@ean"/></Field> <!-- STX Receiver code ref -->
							</RSG>
						
							<MTR>
								<mapper:incVar name="segmentCount"/>
								<Field>
									<mapper:getVar name="segmentCount"/>
								</Field>
							</MTR>			
						</MHD>
					</xsl:if>
					
					<END>
						<Field> <!-- Number of messages in document -->
							<mapper:getVar name="messageCount"/>
						</Field>
					</END>
						
				</STX>
		      
	    </Document>
    </xsl:template>


	<xsl:template match="Invoice">
			<xsl:param name="hubEnvelope"/>
			<xsl:param name="hubDocument"/>

			<mapper:logMessage>
				Invoice number: <xsl:value-of select="InvoiceNumber"/>
			</mapper:logMessage>

			<!-- Perform hub specific validation of this invoice -->
			<xsl:call-template name="validate-invoice-header">
				<xsl:with-param name="hubEnvelope" select="$hubEnvelope"/>
				<xsl:with-param name="hubDocument" select="$hubDocument"/>
				<xsl:with-param name="invoice" select="."/>
			</xsl:call-template>

			<xsl:variable name="hubID"><xsl:value-of select="$hubEnvelope/../@id"/></xsl:variable>
<!--
<mapper:logMessage>
	HUB ID = <xsl:value-of select="$hubID"/>
</mapper:logMessage>
-->
			<!-- Process the invoice itself -->
			<mapper:setVar name="segmentCount">0</mapper:setVar>		
			<MHD>
				<mapper:incVar name="segmentCount"/>
				<mapper:incVar name="messageCount"/>
	
				<!-- Message reference (count in document) -->
				<Field>
					<mapper:getVar name="messageCount"/>
				</Field>
				<!-- Message type -->
				<Field>
					<Field>INVOIC</Field>
					<Field>
						<xsl:if test="$hubDocument/@ver = '9'">9</xsl:if>
						<xsl:if test="$hubDocument/@ver = '8'">8</xsl:if>
					</Field>
				</Field>

				<xsl:variable name="customersLocationCode">
					<xsl:call-template name="get-customers-location-code">
						<xsl:with-param name="ean" select="DeliverTo/EanCode"/>
						<xsl:with-param name="customers" select="DeliverTo/CustomersCode"/>
						<xsl:with-param name="suppliers" select="DeliverTo/SuppliersCode"/>
					</xsl:call-template>
				</xsl:variable>				

				<!-- Customer location -->
				<CLO>
					<mapper:incVar name="segmentCount"/>
					<!-- Location codes -->
					<Field>
						<Field tag="CLO-Ean" maxLen="13"><xsl:value-of select="DeliverTo/EanCode"/></Field> <!-- EAN -->
						<Field tag="CLO-CustomersCode" maxLen="17"><xsl:value-of select="$customersLocationCode"/></Field> <!-- Customer's -->
						<Field tag="CLO-SuppliersCode" maxLen="17"><xsl:value-of select="substring(DeliverTo/SuppliersCode, 1, 17)"/></Field> <!-- Supplier's -->
					</Field>			
			
					<Field tag="CLO-Name" maxLen="40"> <!-- Name -->
						<xsl:choose>
							<xsl:when test="string-length(DeliverTo/Name) &gt; 0">
								<xsl:value-of select="substring(DeliverTo/Name, 1, 40)"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="substring(DeliverTo/Address/Title, 1, 40)"/>
							</xsl:otherwise>
						</xsl:choose>
					</Field>
					<!-- Address -->
					<Field>
						<Field tag="CLO-Add1" maxLen="35"><xsl:value-of select="substring(DeliverTo/Address/Title, 1, 35)"/></Field>					
						<Field tag="CLO-Add2" maxLen="35"><xsl:value-of select="substring(DeliverTo/Address/Street, 1, 35)"/></Field>					
						<Field tag="CLO-Add3" maxLen="35"><xsl:value-of select="substring(DeliverTo/Address/Town, 1, 35)"/></Field>					
						<Field tag="CLO-Add4" maxLen="35"><xsl:value-of select="substring(DeliverTo/Address/City, 1, 35)"/></Field>					
						<Field tag="CLO-Add5" maxLen="8"><xsl:value-of select="substring(DeliverTo/Address/PostCode, 1, 8)"/></Field>
					</Field>
				</CLO>
		
				<!-- Invoice references -->
				<IRF>
					<mapper:incVar name="segmentCount"/>
					<Field tag="Invoice Number" minLen="1" maxLen="17"><xsl:value-of select="InvoiceNumber"/></Field> <!-- Invoice number -->
					<Field> <!-- Invoice Date -->
						<xsl:if test="string-length(InvoiceDate) &gt; 0">
							<date:reformat curFormat="yyyy-MM-dd" newFormat="yyMMdd">
								<xsl:value-of select="InvoiceDate"/>
							</date:reformat>
						</xsl:if>
					</Field>
					<Field> <!-- Taxpoint Date -->
						<xsl:if test="string-length(TaxPointDate) &gt; 0">
							<date:reformat curFormat="yyyy-MM-dd" newFormat="yyMMdd">
								<xsl:value-of select="TaxPointDate"/>
							</date:reformat>
						</xsl:if>
					</Field>
				</IRF>
		
				<!-- Payment terms (may need if settlement discount applies) or some other textual instruction for invoice -->
				<xsl:choose>
					<xsl:when test="$hubDocument/@pyt = 'false'">
						<!-- ignore PYT regardless as the hub does not support it -->
					</xsl:when>
					<xsl:when test="SettlementDiscount/Percentage &gt; 0 or string-length(SettlementDiscount/ExpiresDate) &gt; 0">
						<PYT>
							<mapper:incVar name="segmentCount"/>
							<xsl:if test="$hubDocument/@ver = '9' or $Version = '9'">
								<Field>1</Field> <!-- Sequence (not used in version 8) -->
							</xsl:if>
							<Field maxLen="40"><xsl:value-of select="SettlementDiscount/Terms"/></Field> <!-- Terms of payment -->
							<Field>
								<Field>  <!-- Due date  -->
									<xsl:if test="string-length(SettlementDiscount/ExpiresDate) &gt; 0">
										<date:reformat curFormat="yyyy-MM-dd" newFormat="yyMMdd">
											<xsl:value-of select="SettlementDiscount/ExpiresDate"/>
										</date:reformat>
									</xsl:if>
								</Field>
								<xsl:if test="$hubDocument/@ver = '9' or $Version = '9'">
									<Field type="integer" tag="PYT DSCP">  <!-- Discount percentage  -->
										<xsl:choose>
											<xsl:when test="SettlementDiscount/Percentage &gt;= 0">
												<xsl:value-of select="untdi:convertToUntdiDecimal(SettlementDiscount/Percentage, 3)"/>
											</xsl:when>
											<xsl:when test="string-length(SettlementDiscount/ExpiresDate) &gt; 0">
												<xsl:value-of select="0"/> <!-- default to 0 when a date is supplied but no percentage -->
											</xsl:when>
										</xsl:choose>
									</Field>
								</xsl:if>
							</Field>
							<xsl:if test="$hubDocument/@ver = '9' or $Version = '9'">
								<Field>
									<Field/> <!-- Number of days  -->
									<Field/> <!-- Discount percentage --> 
									<Field/> <!-- Settlement Code  -->
								</Field>
							</xsl:if>
						</PYT>
					</xsl:when>
					<xsl:when test="string-length(SettlementDiscount/Terms) &gt; 0 and $Version = '9'">
						<PYT>
							<mapper:incVar name="segmentCount"/>
							<Field>1</Field> <!-- Sequence -->
							<Field maxLen="40"><xsl:value-of select="SettlementDiscount/Terms"/></Field> <!-- Terms of payment -->
						</PYT>					
					</xsl:when>
					<xsl:when test="string-length(SettlementDiscount/Terms) &gt; 0 and $Version = '8'">
						<PYT>
							<mapper:incVar name="segmentCount"/>
							<Field maxLen="40"><xsl:value-of select="SettlementDiscount/Terms"/></Field> <!-- Terms of payment -->
						</PYT>					
					</xsl:when>
					<!-- Some hubs rely on this even if it isn't used -->
					<xsl:when test="$hubDocument/@pyt = 'true' and $Version = '9'">
						<PYT>
							<mapper:incVar name="segmentCount"/>
							<Field>1</Field> <!-- Sequence -->
							<Field>Anticipated Date</Field> <!-- Terms of payment -->
							<Field>
								<Field>  <!-- Due date, 30 days from today  -->
									<xsl:value-of select="date:adjust(date:insert('yyMMdd'), 'yyMMdd', 30, '+')"/>
								</Field>
								<Field type="integer"  tag="PYT DSCP">  <!-- Discount percentage  -->
									<xsl:value-of select="untdi:convertToUntdiDecimal(0, 3)"/>
								</Field>
							</Field>
						</PYT>
					</xsl:when>
					<xsl:when test="$hubDocument/@pyt = 'true' and $Version = '8'">
						<PYT>
							<mapper:incVar name="segmentCount"/>
							<Field>Anticipated Date</Field> <!-- Terms of payment -->
							<Field>
								<Field>  <!-- Due date, 30 days from today  -->
									<xsl:value-of select="date:adjust(date:insert('yyMMdd'), 'yyMMdd', 30, '+')"/>
								</Field>
							</Field>
						</PYT>
					</xsl:when>
				</xsl:choose>
				
			  <mapper:setVar name="dnaCount">0</mapper:setVar>

				<xsl:for-each select="SpecialInstructions">
					<xsl:if test="string-length(.) &gt; 0">
						<DNA>
							<mapper:incVar name="segmentCount"/>
							<mapper:incVar name="dnaCount"/>
							<Field><mapper:getVar name="dnaCount"/></Field> <!-- Sequence -->
							<Field/> <!-- DNAC -->
							<Field> <!-- RTEX -->
								<Field></Field>
								<Field></Field>
							</Field>
							<Field> <!-- GNAR -->
								<Field><xsl:value-of select="substring(., 1, 40)"/></Field>
								<Field><xsl:value-of select="substring(., 41, 40)"/></Field>
								<Field><xsl:value-of select="substring(., 81, 40)"/></Field>
								<Field><xsl:value-of select="substring(., 121, 40)"/></Field>
							</Field>
						</DNA>
					</xsl:if>
				</xsl:for-each>
				
				<!-- Use DNA to specify carriage charges for some, eg: JLP -->
				<xsl:if test="contains($hubDocument/@dna, 'surcharge') and InvoiceSummary/Surcharge &gt; 0">
					<DNA>
						<mapper:incVar name="segmentCount"/>
						<mapper:incVar name="dnaCount"/>
						<Field><mapper:getVar name="dnaCount"/></Field> <!-- Sequence -->
						<Field/> <!-- DNAC -->
						<Field> <!-- RTEX -->
							<Field>022</Field>  <!-- 022 = carriage charge  -->
							<Field>C</Field>  <!-- C = Carriage charge (VAT liable), D = Delivery charge -->
						</Field>
						<Field> <!-- GNAR -->
							<Field>
								<xsl:value-of select="InvoiceSummary/Surcharge"/> <!-- Stuff it in here for reference -->
							</Field>
						</Field>
					</DNA>
				</xsl:if>
				
				<!-- include DNA for direct to site deliveries for some, eg: NMBS -->
				<xsl:if test="contains($hubDocument/@dna, 'direct') and DeliverTo/@direct = 'true'">
					<DNA>
						<mapper:incVar name="segmentCount"/>
						<mapper:incVar name="dnaCount"/>
						<Field><mapper:getVar name="dnaCount"/></Field> <!-- Sequence -->
						<Field> <!-- DNAC -->
							<Field>22</Field> <!-- UNTDI Code list -->
							<Field>34</Field> <!-- Code list value (34 = direct delivery) -->
						</Field>
						<Field/> <!-- RTEX -->
						<Field/> <!-- GNAR -->
					</DNA>
				</xsl:if>
				
				<xsl:if test="$PutVatIntoDNA = 'true'">
					<DNA>
						<mapper:incVar name="segmentCount"/>
						<mapper:incVar name="dnaCount"/>
						<Field><mapper:getVar name="dnaCount"/></Field> <!-- Sequence -->
						<Field/> <!-- DNAC -->
						<Field/> <!-- RTEX -->
						<Field> <!-- GNAR -->
							<Field>VAT REG. NUMBER</Field>
							<xsl:choose>
								<xsl:when test="Supplier/VatNumber/@type = 'Alpha'">
									<Field><xsl:value-of select="Supplier/VatNumber[@type = 'Alpha']"/></Field>
								</xsl:when>
								<xsl:when test="Supplier/VatNumber/@type = 'Numeric'">
									<Field><xsl:value-of select="Supplier/VatNumber[@type = 'Numeric']"/></Field>
								</xsl:when>
								<xsl:when test="math:isNum(Supplier/VatNumber)">
									<Field><xsl:value-of select="str:last(Supplier/VatNumber, 9)"/></Field>
								</xsl:when>
								<xsl:otherwise>
									<Field><xsl:value-of select="Supplier/VatNumber"/></Field>
								</xsl:otherwise>
							</xsl:choose>							
						</Field>
					</DNA>
				</xsl:if>						
				

                                <mapper:setVar name="oddCount">0</mapper:setVar>
                                
                                <xsl:choose>
                                  <xsl:when test="count(Order) &gt; 0">
                                    <!-- multiple ODDs in use -->
                                    <xsl:for-each select="Order">
                                      <xsl:call-template name="writeODD">
                                        <xsl:with-param name="hubEnvelope" select="$hubEnvelope"/>
                                        <xsl:with-param name="hubDocument" select="$hubDocument"/>
                                        <xsl:with-param name="customersLocationCode" select="$customersLocationCode"/>
                                        <xsl:with-param name="order" select="."/>
                                      </xsl:call-template>
                                    </xsl:for-each>
                                  </xsl:when>
                                  <xsl:otherwise>
                                    <!-- one ODD in use -->
                                    <xsl:call-template name="writeODD">
                                        <xsl:with-param name="hubEnvelope" select="$hubEnvelope"/>
                                        <xsl:with-param name="hubDocument" select="$hubDocument"/>
                                        <xsl:with-param name="customersLocationCode" select="$customersLocationCode"/>
                                        <xsl:with-param name="order" select="."/>
                                    </xsl:call-template>
                                  </xsl:otherwise>
                                </xsl:choose>
                                
				<xsl:if test="string-length(TaxPointDate) &gt; 0">
					<xsl:if test="VatSummary[VatPercentage = 15]">
						<xsl:if test="date:isBefore('01/12/2008', 'dd/MM/yyyy', TaxPointDate, 'yyyy-MM-dd')">
							<mapper:logError>
								Taxpoint date is pre-December 2008 (<xsl:value-of select="TaxPointDate"/>), and 15% Vat Rate is in use. This should be 17.5%.
							</mapper:logError>
						</xsl:if>
						<xsl:if test="date:isAfter('03/01/2011', 'dd/MM/yyyy', TaxPointDate, 'yyyy-MM-dd')">
							<mapper:logError>
								Taxpoint date is after 03/01/2011 (<xsl:value-of select="TaxPointDate"/>) and the tax rate should be 20%, not 15%
							</mapper:logError>
						</xsl:if>
					</xsl:if>
					<xsl:if test="VatSummary[VatPercentage = 17.5]">
						<xsl:if test="date:isAfter('30/11/2008', 'dd/MM/yyyy', TaxPointDate, 'yyyy-MM-dd') and date:isBefore('01/01/2010', 'dd/MM/yyyy', TaxPointDate, 'yyyy-MM-dd')">
							<mapper:logError>
								Taxpoint date is between 01/12/2008 and 31/12/2009 (<xsl:value-of select="TaxPointDate"/>), and 17.5% Vat Rate is in use. This should be 15%.
							</mapper:logError>
						</xsl:if>
						<xsl:if test="date:isAfter('03/01/2011', 'dd/MM/yyyy', TaxPointDate, 'yyyy-MM-dd')">
							<mapper:logError>
								Taxpoint date is after 03/01/2011 (<xsl:value-of select="TaxPointDate"/>) and the tax rate should be 20%, not 17.5%
							</mapper:logError>
						</xsl:if>
					</xsl:if>
					<xsl:if test="VatSummary[VatPercentage = 20]">
						<xsl:if test="date:isBefore('04/01/2011', 'dd/MM/yyyy', TaxPointDate, 'yyyy-MM-dd')">
							<mapper:logError>
								Taxpoint date is before 04/01/2011 (<xsl:value-of select="TaxPointDate"/>), and 20% Vat Rate should not be in use before 1st Jan 2011.
							</mapper:logError>
						</xsl:if>
					</xsl:if>
					<!--
					<xsl:if test="VatSummary[VatPercentage = 17.5]">
						<xsl:if test="not(date:isBefore('01/12/2008', 'dd/MM/yyyy', TaxPointDate, 'yyyy-MM-dd'))">
							<mapper:logError>
								Taxpoint date is post-December 2008, and 17.5% Vat Rate is in use. This should be 15%.
							</mapper:logError>
						</xsl:if>
					</xsl:if>
					-->
				</xsl:if>

				<!-- write out each VAT summary -->
				<xsl:for-each select="VatSummary">
					<xsl:call-template name="InvoiceVatSummary">
						<xsl:with-param name="vatSummary" select="."/>
						<xsl:with-param name="hubDocument" select="$hubDocument"/>
					</xsl:call-template>
				</xsl:for-each>

				<!-- Write out the invoice trailer -->					
				<xsl:call-template name="InvoiceSubTotalSummary">
					<xsl:with-param name="totalSummary" select="InvoiceSummary"/>
					<xsl:with-param name="vatSummaryCount" select="count(VatSummary)"/>
				</xsl:call-template>
				
				<MTR>
					<mapper:incVar name="segmentCount"/>
					<Field>
						<mapper:getVar name="segmentCount"/>
					</Field>
				</MTR>
			</MHD>
									
	</xsl:template>


<xsl:template name="writeODD">                                
  <xsl:param name="hubEnvelope"/>
  <xsl:param name="hubDocument"/>
  <xsl:param name="customersLocationCode"/>
  <xsl:param name="order"/>
  
      <!-- Order and delivery references -->
      <ODD>
              <mapper:incVar name="segmentCount"/>
              <mapper:incVar name="oddCount"/>
              <Field><mapper:getVar name="oddCount"/></Field> <!-- Sequence of ODD -->
                  <Field>
                     <Field tag="Customer Order Number" maxLen="17"> <!-- Customer's order number -->
                        <xsl:choose>
                            <!-- Travis Perkins (live and test) require a concatenation of delivery code + order number -->
                            <xsl:when test="$hubEnvelope/@ean = '5013546019767' or $hubEnvelope/@ean = '5013546128324'">
                              <xsl:choose>
                                  <!-- prob already has it as TP order numbers are usually 5 or 6 digits -->
                                  <xsl:when test="string-length($order/OrderNumber/Customers) = 9">
                                          <xsl:value-of select="$order/OrderNumber/Customers"/>
                                  </xsl:when>
                                  <!-- prob already has it as TP order numbers are usually 5 or 6 digits -->
                                  <xsl:when test="string-length($order/OrderNumber/Customers) = 10">
                                          <xsl:value-of select="$order/OrderNumber/Customers"/>
                                  </xsl:when>
                                  <!-- doesn't have it -->
                                  <xsl:when test="not(starts-with($order/OrderNumber/Customers, $customersLocationCode))">
                                          <xsl:value-of select="concat($customersLocationCode, $order/OrderNumber/Customers)"/>
                                  </xsl:when>
                                  <!-- prob already has it -->
                                  <xsl:otherwise>
                                          <xsl:value-of select="$order/OrderNumber/Customers"/>
                                  </xsl:otherwise>
                              </xsl:choose>								
                            </xsl:when>
                            <xsl:otherwise><xsl:value-of select="$order/OrderNumber/Customers"/></xsl:otherwise>
                        </xsl:choose>							
                      </Field>
                      <Field tag="Supplier Order Number" maxLen="17"><xsl:value-of select="$order/OrderNumber/Suppliers"/></Field> <!-- Supplier's order number -->
                        <Field> <!-- Date order placed -->
                                <xsl:if test="string-length($order/OrderDate/Customers) &gt; 0">
                                        <date:reformat curFormat="yyyy-MM-dd" newFormat="yyMMdd">
                                                <xsl:value-of select="$order/OrderDate/Customers"/>
                                        </date:reformat>
                                </xsl:if>						
                        </Field>								
                        <Field> <!-- Date order received -->
                                <xsl:if test="string-length($order/OrderDate/Suppliers) &gt; 0">
                                        <date:reformat curFormat="yyyy-MM-dd" newFormat="yyMMdd">
                                                <xsl:value-of select="$order/OrderDate/Suppliers"/>
                                        </date:reformat>
                                </xsl:if>						
                        </Field>
                      </Field>
                      <Field>
                              <!-- Delivery note number -->
                              <Field tag="Delivery Note Number" maxLen="17"><xsl:value-of select="$order/DeliveryNoteNumber"/></Field>
                              <!-- date of delivery -->
                              <Field>
                                      <xsl:if test="string-length($order/DeliveryNoteDate) &gt; 0">
                                              <date:reformat curFormat="yyyy-MM-dd" newFormat="yyMMdd">
                                                      <xsl:value-of select="$order/DeliveryNoteDate"/>
                                              </date:reformat>
                                      </xsl:if>						
                              </Field>
                      </Field>
                      <Field> <!-- number of delivered units -->
                              <xsl:if test="$order/DeliveredPallets &gt; 0">
                                      <xsl:value-of select="round($order/DeliveredPallets)"/>
                              </xsl:if>
                      </Field> 
                      <Field>						
                              <Field> <!-- delivery weights -->
                                      <xsl:if test="$order/DeliveredWeight &gt; 0">
                                              <xsl:value-of select="untdi:convertToUntdiDecimal($order/DeliveredWeight, 3)"/>
                                      </xsl:if>
                              </Field> 
                              <Field/> <!-- vehicle tare weights -->
                      </Field>
                      <Field>
                              <!-- proof of delivery number PODN -->
                              <Field tag="POD Number" maxLen="17">
                                      <xsl:choose>
                                              <xsl:when test="string-length($order/DeliveryProofNumber) &gt; 0">
                                                      <xsl:value-of select="$order/DeliveryProofNumber"/>
                                              </xsl:when>
                                              <xsl:otherwise>
                                                      <xsl:value-of select="$order/DeliveryNoteNumber"/>
                                              </xsl:otherwise>
                                      </xsl:choose>
                              </Field>
                              <!-- date delivered -->
                              <Field>
                                      <xsl:choose>
                                              <xsl:when test="string-length($order/DeliveryDate) &gt; 0">
                                                      <date:reformat curFormat="yyyy-MM-dd" newFormat="yyMMdd">
                                                              <xsl:value-of select="$order/DeliveryDate"/>
                                                      </date:reformat>
                                              </xsl:when>						
                                              <xsl:when test="string-length($order/DeliveryNoteDate) &gt; 0">
                                                      <date:reformat curFormat="yyyy-MM-dd" newFormat="yyMMdd">
                                                              <xsl:value-of select="$order/DeliveryNoteDate"/>
                                                      </date:reformat>
                                              </xsl:when>						
                                              <xsl:when test="string-length($order/DeliveredDate) &gt; 0">
                                                      <date:reformat curFormat="yyyy-MM-dd" newFormat="yyMMdd">
                                                              <xsl:value-of select="$order/DeliveredDate"/>
                                                      </date:reformat>
                                              </xsl:when>						
                                      </xsl:choose>
                              </Field>
                        </Field>
                        <Field/> <!-- name of carrier -->
                        <Field>
                                <Field/> <!-- Supplier's despatch EAN location code -->
                                <Field/> <!-- Supplier's own location code -->
                        </Field>
                        <Field>
                                <Field/> <!-- Trans shipment EAN location code -->
                                <Field/> <!-- Supplier's own location code -->
                        </Field>

                        <xsl:if test="count($order/InvoiceLine) = 0">
                                <mapper:logError>
                                        No invoice lines in invoice number <xsl:value-of select="$order/InvoiceNumber"/>. This is mandatory within Tradacoms UNTDI.
                                </mapper:logError>
                        </xsl:if>

                        <xsl:apply-templates select="$order/InvoiceLine">
                                <xsl:with-param name="hubEnvelope" select="$hubEnvelope"/>
                                <xsl:with-param name="hubDocument" select="$hubDocument"/>
                                <xsl:with-param name="oddSeq" select="mapper:getVar('oddCount')"/>
                        </xsl:apply-templates>

                </ODD>
</xsl:template>

	<!--
		Process an invoice line
	-->
	<xsl:template match="InvoiceLine">
		<xsl:param name="hubEnvelope"/>
		<xsl:param name="hubDocument"/>
		<xsl:param name="oddSeq"/>

		<!-- Perform hub specific validation of this line -->
		<xsl:call-template name="validate-invoice-line">
			<xsl:with-param name="hubEnvelope" select="$hubEnvelope"/>
			<xsl:with-param name="hubDocument" select="$hubDocument"/>
			<xsl:with-param name="line" select="."/>
		</xsl:call-template>
		
<!-- Donna work               <mapper:setVar name="places">
                  <xsl:choose>
                    <xsl:when test="$ForceTwoDecPlaces = 'true'">'0.00'</xsl:when>
                    <xsl:otherwise>'0.0000'</xsl:otherwise>
                  </xsl:choose>
                </mapper:setVar>
    -->                    
			<xsl:variable name="hubID"><xsl:value-of select="$hubEnvelope/../@id"/></xsl:variable>

			<mapper:removeVar name="UOM"/>
			<mapper:removeVar name="AmountPerUnit"/>
			<mapper:removeVar name="MeasurePerUnit"/>
			<mapper:removeVar name="UnitsOrdered"/>

			<xsl:variable name="amountPerUnit">
				<xsl:choose>
					<xsl:when test="Quantity/AmountPerUnit &gt; 0">
						<xsl:value-of select="Quantity/AmountPerUnit"/>
					</xsl:when>
					<xsl:otherwise>1</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>

			<xsl:choose>
				<xsl:when test="Quantity/MeasureIndicator = 'Each' or Quantity/MeasureIndicator = 'Case' or Quantity/MeasureIndicator = 'Pack' or Quantity/MeasureIndicator = 'Box' or string-length(Quantity/MeasureIndicator) = 0">
					<mapper:setVar name="AmountPerUnit">
						<xsl:value-of select="$amountPerUnit"/>
					</mapper:setVar>
					<mapper:setVar name="UnitsOrdered">
						<xsl:value-of select="Quantity/Amount"/>
					</mapper:setVar>
				</xsl:when>
				<xsl:when test="Quantity/MeasureIndicator = 'EA' or Quantity/MeasureIndicator = 'CS' or Quantity/MeasureIndicator = 'PK' or Quantity/MeasureIndicator = 'BX'">
					<mapper:setVar name="AmountPerUnit">
						<xsl:value-of select="$amountPerUnit"/>
					</mapper:setVar>
					<mapper:setVar name="UnitsOrdered">
						<xsl:value-of select="Quantity/Amount"/>
					</mapper:setVar>
				</xsl:when>
				<xsl:otherwise>
					<mapper:setVar name="AmountPerUnit">0</mapper:setVar>
					<mapper:setVar name="MeasurePerUnit">
						<xsl:value-of select="$amountPerUnit"/>
					</mapper:setVar>
					<mapper:setVar name="UnitsOrdered">
						<xsl:value-of select="Quantity/Amount"/>
					</mapper:setVar>
					<xsl:choose>
						<xsl:when test="Quantity/MeasureIndicator = 'Metre'"><mapper:setVar name="UOM">M</mapper:setVar></xsl:when>
						<xsl:when test="Quantity/MeasureIndicator = 'Square Metre'"><mapper:setVar name="UOM">M2</mapper:setVar></xsl:when>
						<xsl:when test="Quantity/MeasureIndicator = 'Square Metres'"><mapper:setVar name="UOM">M2</mapper:setVar></xsl:when>
						<xsl:when test="Quantity/MeasureIndicator = 'Square Meters'"><mapper:setVar name="UOM">M2</mapper:setVar></xsl:when>
						<xsl:when test="Quantity/MeasureIndicator = 'Kilogramme'"><mapper:setVar name="UOM">KG</mapper:setVar></xsl:when>
						<xsl:when test="Quantity/MeasureIndicator = 'Kilogram'"><mapper:setVar name="UOM">KG</mapper:setVar></xsl:when>
						<xsl:when test="Quantity/MeasureIndicator = 'Gram'"><mapper:setVar name="UOM">G</mapper:setVar></xsl:when>
						<xsl:when test="Quantity/MeasureIndicator = 'Tonne'"><mapper:setVar name="UOM">T</mapper:setVar></xsl:when>
						<xsl:when test="Quantity/MeasureIndicator = 'Ton'"><mapper:setVar name="UOM">T</mapper:setVar></xsl:when>
						<xsl:when test="Quantity/MeasureIndicator = 'Litre'"><mapper:setVar name="UOM">L</mapper:setVar></xsl:when>
						<xsl:when test="Quantity/MeasureIndicator = 'Bag'"><mapper:setVar name="UOM">BG</mapper:setVar></xsl:when>
						<xsl:when test="Quantity/MeasureIndicator = 'Roll'"><mapper:setVar name="UOM">RL</mapper:setVar></xsl:when>
						<xsl:when test="Quantity/MeasureIndicator = 'Case'"><mapper:setVar name="UOM">CS</mapper:setVar></xsl:when>
						<xsl:when test="math:isNum(Quantity/MeasureIndicator)"><mapper:setVar name="UOM"><xsl:value-of select="Quantity/MeasureIndicator"/></mapper:setVar></xsl:when>
						<xsl:otherwise>
							<xsl:choose>
								<xsl:when test="string-length(Quantity/MeasureIndicator) &lt;= 3">
									<mapper:logWarning>
										Unsupported or incorrect UOM code in generic document: <xsl:value-of select="Quantity/MeasureIndicator"/>
									</mapper:logWarning>
									<mapper:setVar name="UOM">
										<xsl:value-of select="Quantity/MeasureIndicator"/>
									</mapper:setVar>
								</xsl:when>
								<xsl:otherwise>
									<mapper:logError>
										Unsupported or incorrect UOM code in generic document: <xsl:value-of select="Quantity/MeasureIndicator"/>
									</mapper:logError>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>			
			</xsl:choose>
	
			<xsl:variable name="BUCT"><xsl:value-of select="format-number(Price/UnitPrice, '0.0000')"/></xsl:variable>
			<xsl:variable name="ItemDiscount">
				<xsl:choose> <!-- Avoid divide by zero on zero quantities -->
					<xsl:when test="Quantity/Amount = 0">
						<xsl:value-of select="0"/>
					</xsl:when>
					<xsl:when test="count(Price/LineDiscount) &gt; 1"> <!-- Will need to do CIAs, but here just add the discounts to make a grand total discount which goes into the DSCV -->
						<mapper:setVar name="discountTotal">0</mapper:setVar>
						<xsl:for-each select="Price/LineDiscount">
							<mapper:addToVar name="discountTotal"><xsl:value-of select="."/></mapper:addToVar>
						</xsl:for-each>
						<xsl:value-of select="format-number(mapper:getVar('discountTotal') div Quantity/Amount, '0.0000000')"/>
					</xsl:when>
					<xsl:when test="not(Price/LineDiscount) or not(Price/LineDiscount &gt;= 0)">
						<xsl:value-of select="0"/>
					</xsl:when>
					<!-- A divisor on the price per -->
					<xsl:when test="Price/LineDiscount &gt; 0 and math:isNum(Price/MeasureIndicator)">
						<xsl:value-of select="format-number(Price/LineDiscount div (Quantity/Amount div Price/MeasureIndicator), '0.0000000')"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="format-number(Price/LineDiscount div Quantity/Amount, '0.0000000')"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="AUCT">
                          <xsl:choose>
                            <xsl:when test="Price/NetUnitPrice &gt;= 0">
                              <xsl:value-of select="format-number(Price/NetUnitPrice, '0.0000')"/>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:value-of select="format-number($BUCT - $ItemDiscount, '0.0000000')"/>
                            </xsl:otherwise>
                          </xsl:choose>
                        </xsl:variable>
			<xsl:variable name="DSCP"> <!-- Avoid divide by zero errors on zero value invoice lines -->
				<xsl:choose>
					<xsl:when test="$ItemDiscount = 0">
						<xsl:value-of select="0.0000"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="format-number(($ItemDiscount div $BUCT) * 100, '0.00')"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<!-- Round these to two and then to four to ensure compatibility with BOS that do crap rounding of 4-dec places (such as Unimer) -->
			<xsl:variable name="LEXC">
				<xsl:choose>
					<xsl:when test="Price/LineTotal != 0">
						<xsl:value-of select="Price/LineTotal"/>
					</xsl:when>
					<xsl:when test="string-length(Product/PackageCode) = 14 or string-length(Product/PalletCode) = 14">
						<!-- Lines reported as packages rather than singletons need to calculate with that in mind too -->
						<!-- BULLSHIT as the AUCT and BUCT is cost of a BOX not a product in a box - what a DER!!!!! -->
<!--						<xsl:value-of select="format-number(format-number($AUCT * Quantity/Amount * Quantity/AmountPerUnit, '0.00'), '0.0000')"/> -->
						<xsl:value-of select="format-number(format-number(($AUCT * Quantity/Amount) + 0.001, '0.00'), '0.0000')"/>
					</xsl:when>
					<xsl:otherwise>
						<!-- normal item level calculation -->
						<xsl:value-of select="format-number(format-number(($AUCT * Quantity/Amount) + 0.001, '0.00'), '0.0000')"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="DSCV">
				<xsl:choose>
					<xsl:when test="Price/LineDiscount &gt; 0">
						<xsl:value-of select="Price/LineDiscount"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="format-number(format-number(($ItemDiscount * Quantity/Amount) + 0.001, '0.00'), '0.0000')"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
	
			<xsl:if test="Price/LineTotal &gt; 0">
				<xsl:if test="math:abs($LEXC) - math:abs(Price/LineTotal) &gt; 0.1">
					<mapper:logError>
						Unnacceptable difference of <xsl:value-of select="math:abs($LEXC - Price/LineTotal)"/> between supplied line total <xsl:value-of select="Price/LineTotal"/> and that calculated of <xsl:value-of select="$LEXC"/>
					</mapper:logError>
				</xsl:if>
			</xsl:if>
	
<!--			<mapper:logError>
				QTY = <xsl:value-of select="Quantity/Amount"/> Quantity/Amount
				LDISC = <xsl:value-of select="Price/LineDiscount"/> Price/LineDiscount
				BUCT = <xsl:value-of select="$BUCT"/>
				Item Disc = <xsl:value-of select="$ItemDiscount"/> Price/LineDiscount div Quantity/Amount
				AUCT = <xsl:value-of select="$AUCT"/>  (BUCT - ItemDiscount)
				DSCP = <xsl:value-of select="$DSCP"/> ($ItemDiscount div $BUCT) * 100
				DSCV = <xsl:value-of select="$DSCV"/> ($ItemDiscount * Quantity/Amount)
				LEXC = <xsl:value-of select="$LEXC"/> ($AUCT * Quantity/Amount)
			</mapper:logError>
	-->
			<ILD>
				<mapper:incVar name="segmentCount"/>
				<Field><xsl:value-of select="$oddSeq"/></Field> <!-- Sequence of ODD this is in -->
				<mapper:setVar name="ildSeq"><xsl:value-of select="position()"/></mapper:setVar>
				<Field><xsl:value-of select="mapper:getVar('ildSeq')"/></Field> <!-- Sequence of ILD within OLD -->
				<Field>
					<Field maxLen="13"><xsl:value-of select="Product/EanCode"/></Field> <!-- EAN code of product -->
					<Field maxLen="40"><xsl:value-of select="Product/SuppliersCode"/></Field> <!-- Supplier code of product -->
					<Field maxLen="14"> <!-- DUN code of product, this is stuck on the box that carries a number of products -->
						<xsl:choose>
							<xsl:when test="string-length(Product/PackageCode) = 14">
								<xsl:value-of select="Product/PackageCode"/>
							</xsl:when>
							<xsl:when test="string-length(Product/PalletCode) = 14">
								<xsl:value-of select="Product/PalletCode"/>
							</xsl:when>
						</xsl:choose>
					</Field>
				</Field>
				<Field maxLen="13"> <!-- Supplier EAN code for consigned units -->
					<xsl:choose>
						<xsl:when test="string-length(Product/InnerBarcode) = 13"> <!-- EAN13 -->
							<xsl:value-of select="Product/InnerBarcode"/>
						</xsl:when>
						<xsl:when test="string-length(Product/InnerBarcode) = 8"> <!-- Pad to 13 if EAN8 -->
							<xsl:value-of select="'00000'"/><xsl:value-of select="Product/InnerBarcode"/>
						</xsl:when>
						<xsl:when test="string-length(Product/InnerBarcode) = 0"> <!-- Not supplied -->
						</xsl:when>

						<!-- Trap any which have not been updated -->
						<xsl:when test="string-length(Product/PackageCode) != 14 and string-length(Product/PackageCode) != 0">
							<mapper:logError>
								Package Code is still being mapped and should now be InnerBarcode: <xsl:value-of select="Product/PackageCode"/>
							</mapper:logError>
						</xsl:when>
<!--						
						<xsl:when test="string-length(Product/PackageCode) = 8">
							<xsl:value-of select="'00000'"/><xsl:value-of select="Product/PackageCode"/>
						</xsl:when>
						<xsl:when test="string-length(Product/PackageCode) = 13">
							<xsl:value-of select="Product/PackageCode"/>
						</xsl:when>
						<xsl:when test="string-length(Product/PalletCode) = 13">
							<xsl:value-of select="Product/PalletCode"/>
						</xsl:when>
						<xsl:when test="string-length(Product/PackageCode) = 0">
						</xsl:when>
						<xsl:when test="string-length(Product/PackageCode) = 14">
						</xsl:when>
-->						
						<xsl:otherwise>
							<mapper:logError>
								SACU consumer unit Code <xsl:value-of select="Product/InnerBarcode"/> is illegal length. Should by EAN8 or EAN13.
							</mapper:logError>
						</xsl:otherwise>
					</xsl:choose>
				</Field> 
				<Field>
					<Field/> <!-- Customer's own brand EAN code -->
					<!-- Customer's own code -->
					<Field maxLen="30">
						<xsl:value-of select="Product/CustomersCode"/>
					<!--
						<xsl:choose>
							<xsl:when test="string-length(Product/CustomersCode) = 0">
								<xsl:value-of select="Product/InnerBarcode"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="Product/CustomersCode"/>
							</xsl:otherwise>
						</xsl:choose>						
						-->
					</Field>
				</Field>
				<Field> <!-- UNOR -->
					<Field type="integer" tag="UNOR"> <!-- Consumer units in traded unit -->
						<xsl:if test="mapper:getVar('AmountPerUnit') &gt; 0">
							<xsl:value-of select="round(mapper:getVar('AmountPerUnit'))"/>
						</xsl:if>
					</Field>  
					<Field>
						<xsl:if test="mapper:getVar('MeasurePerUnit') &gt; 0">
							<xsl:value-of select="untdi:convertToUntdiDecimal(mapper:getVar('MeasurePerUnit'), 3)"/>
						</xsl:if>
					</Field>
					<!-- Ordering measure -->
					<Field> <!-- Measure indicator -->
						<xsl:value-of select="mapper:getVar('UOM')"/>
					</Field>
				</Field>
				<Field> <!-- QTYI -->
					<Field type="integer" tag="QTYI"> <!-- Number of units ordered on invoice -->
						<xsl:if test="mapper:getVar('AmountPerUnit') &gt; 0">
							<xsl:if test="mapper:getVar('UnitsOrdered') &gt;= 0">
								<xsl:value-of select="round(mapper:getVar('UnitsOrdered'))"/>
							</xsl:if>
						</xsl:if>
					</Field>
					<!-- Total measure ordered -->
					<xsl:if test="mapper:getVar('MeasurePerUnit') &gt; 0">
						<Field>
							<xsl:if test="mapper:getVar('UnitsOrdered') &gt; 0">
								<xsl:value-of select="round(mapper:getVar('UnitsOrdered') * 1000)"/> <!-- * 1000 for implied decimal -->
							</xsl:if>
						</Field>
						<!-- Measure indicator (only used if total measure used) -->					 
						<Field>
							<xsl:value-of select="mapper:getVar('UOM')"/>
						</Field>
					</xsl:if>
				</Field>
				<Field> <!-- AUCT -->
					<Field type="integer" tag="AUCT"><xsl:value-of select="untdi:convertToUntdiDecimal(format-number($AUCT, '0.0000'), 4)"/></Field> <!-- Cost price with discount applied -->
					 <!-- price per measure indicator -->
					<Field>
						<xsl:choose>
							<xsl:when test="Price/MeasureIndicator = 'Each'">EA</xsl:when>
							<xsl:when test="Price/MeasureIndicator = 'Metre'">M</xsl:when>
							<xsl:when test="Price/MeasureIndicator = 'Square Metre'">M2</xsl:when>
							<xsl:when test="Price/MeasureIndicator = 'Square Metres'">M2</xsl:when>
							<xsl:when test="Price/MeasureIndicator = 'Square Meters'">M2</xsl:when>
							<xsl:when test="Price/MeasureIndicator = 'Kilogramme'">KG</xsl:when>
							<xsl:when test="Price/MeasureIndicator = 'Kilogram'">KG</xsl:when>
							<xsl:when test="Price/MeasureIndicator = 'Gram'">G</xsl:when>
							<xsl:when test="Price/MeasureIndicator = 'Tonne'">T</xsl:when>
							<xsl:when test="Price/MeasureIndicator = 'Ton'">T</xsl:when>
							<xsl:when test="Price/MeasureIndicator = 'Litre'">L</xsl:when>
							<xsl:when test="Price/MeasureIndicator = 'Bag'">BG</xsl:when>
							<xsl:when test="Price/MeasureIndicator = 'Roll'">RL</xsl:when>
							<xsl:when test="Price/MeasureIndicator = 'Case'">CS</xsl:when>
							<xsl:when test="math:isNum(Price/MeasureIndicator)"><xsl:value-of select="Price/MeasureIndicator"/></xsl:when>
							<xsl:when test="string-length(Price/MeasureIndicator) &lt;= 3"><xsl:value-of select="Price/MeasureIndicator"/></xsl:when>
						</xsl:choose>
					</Field>
				</Field>
				<Field type="integer" tag="LEXC"><xsl:value-of select="untdi:convertToUntdiDecimal(format-number($LEXC, '0.0000'), 4)"/></Field> <!-- LEXC Extended line cost -->
				<Field><xsl:value-of select="Vat/Code"/></Field> <!-- VATC VAT code -->
<!--				
				<xsl:if test="Vat/Percentage = 17.5">
					<mapper:logError>
						17.5% VAT is still in use at line level. This should be 15% now !!!
					</mapper:logError>
				</xsl:if>
-->				
				<Field type="integer" tag="VATP"><xsl:value-of select="untdi:convertToUntdiDecimal(Vat/Percentage, 3)"/></Field> <!-- VATP VAT percentage -->
				<Field/> <!-- MIXI Mixed rate VAT indicator -->
				<!-- CRLI Credit line indicator -->
				<Field><xsl:if test="@credited = 'true'">H</xsl:if></Field>
				<Field> <!-- TDES -->
					<xsl:choose>
						<xsl:when test="count(Product/Name) &gt; 1">
							<Field><xsl:value-of select="substring(Product/Name[1], 1, 40)"/></Field> <!-- Description line 1 -->
							<Field><xsl:value-of select="substring(Product/Name[2], 1, 40)"/></Field> <!-- Description line 2 -->
						</xsl:when>
						<xsl:otherwise>
							<Field><xsl:value-of select="substring(Product/Name, 1, 40)"/></Field> <!-- Description line 1 -->
							<Field><xsl:value-of select="substring(Product/Name, 41, 40)"/></Field> <!-- Description line 2 -->
						</xsl:otherwise>
					</xsl:choose>
				</Field>
				<Field> <!-- MSPR -->
                                        <!-- Manufacturer's suggested retail price -->
					<Field>
                                          <xsl:if test="Price/SellingPrice &gt; 0">
                                            <xsl:value-of select="untdi:convertToUntdiDecimal(format-number(Price/SellingPrice, '0.0000'), 4)"/>
                                          </xsl:if>
                                        </Field>
					<Field/> <!-- Marked price -->
					<Field/> <!-- Split pack price -->
				</Field>
				<Field/> <!-- SRSP Statuary retail price -->
				<Field type="integer" tag="BUCT"><xsl:value-of select="untdi:convertToUntdiDecimal(format-number($BUCT, '0.0000'), 4)"/></Field> <!-- BUCT Unit cost before discount -->
				<Field type="integer" tag="DSCV"><xsl:value-of select="untdi:convertToUntdiDecimal(format-number($DSCV, '0.0000'), 4)"/></Field> <!-- DSCV Discount value for this line ((BUCT - AUCT) * QTYI ) -->
				<Field type="integer" tag="DSCP">
					<xsl:choose>
						<xsl:when test="$IgnoreDSCP = 'true'">
							<xsl:value-of select="''"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="untdi:convertToUntdiDecimal(format-number($DSCP, '0.0000'), 3)"/>
						</xsl:otherwise>
					</xsl:choose>					
				</Field> <!-- DSCP Discount percentage -->
				<Field/> <!-- SUBA Subsidy amount -->
				<Field/> <!-- PIND Special price indicator -->
				<Field/> <!-- IGPI Item group ID -->
				<Field/> <!-- CSDI - Cash settlement discount ID -->
				<Field></Field> <!-- TSUP - Type of Supply (A = ordinary sale) -->				
				<Field> <!-- Spec and contract refs -->
					<Field/> <!-- specification number -->
					<Field/> <!-- contract reference -->
				</Field>
				
				<xsl:if test="count(Price/LineDiscount) &gt; 1"> <!-- Will need to do CIAs, but here just add the discounts to make a grand total discount which goes into the DSCV -->
					<xsl:for-each select="Price/LineDiscount">
						<CIA>
							<mapper:incVar name="segmentCount"/>
							<Field><xsl:value-of select="$oddSeq"/></Field> <!-- ODD sequence -->
							<Field><xsl:value-of select="mapper:getVar('ildSeq')"/></Field> <!-- ILD sequence -->
							<Field><xsl:value-of select="position()"/></Field> <!-- CIA sequence -->
							<Field>B</Field> <!-- Discount type (A = special, B = basic, Q = quantity, V = value)-->
							<Field>A</Field> <!-- A = allowance, C = charge -->
							<Field> <!-- Rules, gross or nett -->
								<xsl:choose>
									<xsl:when test="@type = 'gross'">G</xsl:when>
									<xsl:otherwise>N</xsl:otherwise>
								</xsl:choose>
							</Field>
							<Field>
								<Field></Field> <!-- percentage -->
								<Field><xsl:value-of select="untdi:convertToUntdiDecimal(., 3)"/></Field> <!-- amount -->
							</Field>
						</CIA>
						<mapper:addToVar name="discountTotal"><xsl:value-of select="."/></mapper:addToVar>
					</xsl:for-each>
				</xsl:if>
								
			</ILD>
			
                        <!-- This is commonly used by the book industry -->
                        <xsl:if test="string-length(Product/OrderLineReference) &gt; 0">
                          <DNC>
                            <mapper:incVar name="segmentCount"/>
                            <Field><xsl:value-of select="$oddSeq"/></Field>
                            <Field><xsl:value-of select="mapper:getVar('ildSeq')"/></Field>
                            <Field>1</Field>
                            <Field/>
                            <Field>
                              <Field>082</Field>
                              <Field><xsl:value-of select="Product/OrderLineReference"/></Field>
                            </Field>
                          </DNC>
                        </xsl:if>
                        
			<xsl:for-each select="DataNarrative">
				<DNC>
					<mapper:incVar name="segmentCount"/>
					<Field><xsl:value-of select="$oddSeq"/></Field>
					<Field><xsl:value-of select="mapper:getVar('ildSeq')"/></Field>
					<Field>
						<Field tag="DNAC-01" type="integer">
							<xsl:value-of select="Code/TableNumber"/>
						</Field>
						<Field tag="DNAC-02">
							<xsl:value-of select="Code/Value"/>
						</Field>
					</Field>
					<Field>
						<Field tag="RTEX-01">
							<xsl:value-of select="RegisteredText[1]/Code"/>
						</Field>
						<Field tag="RTEX-02">
							<xsl:value-of select="RegisteredText[1]/Text"/>
						</Field>
						<Field tag="RTEX-03">
							<xsl:value-of select="RegisteredText[2]/Code"/>
						</Field>
						<Field tag="RTEX-04">
							<xsl:value-of select="RegisteredText[2]/Text"/>
						</Field>
						<Field tag="RTEX-05">
							<xsl:value-of select="RegisteredText[3]/Code"/>
						</Field>
						<Field tag="RTEX-06">
							<xsl:value-of select="RegisteredText[3]/Text"/>
						</Field>
						<Field tag="RTEX-07">
							<xsl:value-of select="RegisteredText[4]/Code"/>
						</Field>
						<Field tag="RTEX-08">
							<xsl:value-of select="RegisteredText[4]/Text"/>
						</Field>
					</Field>
					<Field>
						<Field tag="GNAR-01">
							<xsl:value-of select="GeneralNarrative[1]"/>
						</Field>
						<Field tag="GNAR-02">
							<xsl:value-of select="GeneralNarrative[2]"/>
						</Field>
						<Field tag="GNAR-03">
							<xsl:value-of select="GeneralNarrative[3]"/>
						</Field>
						<Field tag="GNAR-04">
							<xsl:value-of select="GeneralNarrative[4]"/>
						</Field>
					</Field>
				</DNC>
			</xsl:for-each>
		
			<xsl:for-each select="Product/FreeText">
				<xsl:if test="string-length(.) &gt; 0">
					<DNC>
						<mapper:incVar name="segmentCount"/>
						<Field><xsl:value-of select="$oddSeq"/></Field> <!-- ODD seq -->
						<Field><xsl:value-of select="mapper:getVar('ildSeq')"/></Field> <!-- ILD seq -->
						<Field/> <!-- DNAC -->
						<Field> <!-- RTEX -->
							<Field></Field>
							<Field></Field>
						</Field>
						<Field> <!-- GNAR -->
							<Field><xsl:value-of select="substring(., 1, 40)"/></Field>
							<Field><xsl:value-of select="substring(., 41, 40)"/></Field>
							<Field><xsl:value-of select="substring(., 81, 40)"/></Field>
							<Field><xsl:value-of select="substring(., 121, 40)"/></Field>
						</Field>
					</DNC>
				</xsl:if>
			</xsl:for-each>
		
	</xsl:template>

	<xsl:template name="InvoiceVatSummary">
		<xsl:param name="vatSummary"/>		
		<xsl:param name="hubDocument"/>		
<!--
		<xsl:if test="VatPercentage = 17.5">
			<mapper:logError>
				17.5% VAT is still in use at VAT summary level. This should be 15% now !!!
			</mapper:logError>
		</xsl:if>
-->
		<STL>
			<mapper:incVar name="segmentCount"/>
			<Field><xsl:value-of select="position()"/></Field> <!-- Sequence -->			
			<xsl:if test="$hubDocument/@ver = '8'">
				<Field></Field> <!-- Version 8 IGPI -->
			</xsl:if>
			<Field><xsl:value-of select="VatCode"/></Field> <!-- VAT Code -->
			<Field type="integer" tag="VATSUM VATP"><xsl:value-of select="untdi:convertToUntdiDecimal(VatPercentage, 3)"/></Field> <!-- VAT Percentage -->
			<Field type="integer"><xsl:value-of select="ApplicableLines"/></Field> <!-- Number of lines it applies to -->
			<Field type="integer" tag="VATSUM SUBT"><xsl:value-of select="untdi:convertToUntdiDecimal(Total1, 2)"/></Field> <!-- Sub total (excluding VAT) before discounts/surcharges -->
			<xsl:choose>
				<xsl:when test="$vatSummary/Discount/@type = 'quantity'">
					<Field type="integer" tag="VATSUM DISC"><xsl:value-of select="untdi:convertToUntdiDecimal(Discount, 2)"/></Field> <!-- Discount amount for invoice quantity -->
					<Field type="integer">000</Field> <!-- Discount amount for invoice value -->
				</xsl:when>
				<xsl:otherwise>
					<Field type="integer">000</Field> <!-- Discount amount for invoice quantity -->
					<Field type="integer" tag="VATSUM DISC"><xsl:value-of select="untdi:convertToUntdiDecimal(Discount, 2)"/></Field> <!-- Discount amount for invoice value -->
				</xsl:otherwise>
			</xsl:choose>			
			<Field type="integer" tag="VATSUM SURA"><xsl:value-of select="untdi:convertToUntdiDecimal(Surcharge, 2)"/></Field> <!-- Surcharge amount -->
			<Field type="integer" tag="VATSUM SUBS"><xsl:value-of select="untdi:convertToUntdiDecimal(Subsidy, 2)"/></Field> <!-- Subtotal subsidy -->
			<Field type="integer" tag="VATSUM TOT2"><xsl:value-of select="untdi:convertToUntdiDecimal(Total2, 2)"/></Field> <!-- Extended sub-total amount (excluding VAT) inc surcharges/discounts -->
			<Field type="integer" tag="VATSUM SDISC"><xsl:value-of select="untdi:convertToUntdiDecimal(SettlementDiscount, 2)"/></Field> <!-- Subtotal of settlement discount -->
			<Field type="integer" tag="VATSUM TOT3"><xsl:value-of select="untdi:convertToUntdiDecimal(Total3, 2)"/></Field> <!-- Extended subtotal after settlement discount -->
			<Field type="integer" tag="VATSUM VATA"><xsl:value-of select="untdi:convertToUntdiDecimal(VatAmount, 2)"/></Field> <!-- VAT Amount payable -->
			<Field type="integer" tag="VATSUM TOT4"><xsl:value-of select="untdi:convertToUntdiDecimal(Total4, 2)"/></Field> <!-- What to pay excluding settlment discount -->
			<Field type="integer" tag="VATSUM TOT5"><xsl:value-of select="untdi:convertToUntdiDecimal(Total5, 2)"/></Field> <!-- What to pay including settlment discount -->
		</STL>		
	</xsl:template>

	<xsl:template name="InvoiceSubTotalSummary">
		<xsl:param name="totalSummary"/>
		<xsl:param name="vatSummaryCount"/>
		<TLR>
			<mapper:incVar name="segmentCount"/>
			<Field type="integer"><xsl:value-of select="$vatSummaryCount"/></Field> <!-- Number of STLs -->
			<Field type="integer" tag="INVSUM TOT1"><xsl:value-of select="untdi:convertToUntdiDecimal($totalSummary/Total1, 2)"/></Field> <!-- Line total excluding VAT and discounts, etc -->
			<xsl:choose>
				<xsl:when test="$totalSummary/Discount/@type = 'quantity'">
					<Field type="integer" tag="INVSUM DISC"><xsl:value-of select="untdi:convertToUntdiDecimal($totalSummary/Discount, 2)"/></Field> <!-- Total discount for invoice quantity -->
					<Field type="integer"><xsl:value-of select="untdi:convertToUntdiDecimal(0, 2)"/></Field> <!-- Total discount for invoice value -->
				</xsl:when>
				<xsl:otherwise>
					<Field type="integer"><xsl:value-of select="untdi:convertToUntdiDecimal(0, 2)"/></Field> <!-- Total discount for invoice quantity -->
					<Field type="integer" tag="INVSUM TOT1"><xsl:value-of select="untdi:convertToUntdiDecimal($totalSummary/Discount, 2)"/></Field> <!-- Total discount for invoice value -->
				</xsl:otherwise>
			</xsl:choose>			
			<Field type="integer" tag="INVSUM SURA"><xsl:value-of select="untdi:convertToUntdiDecimal($totalSummary/Surcharge, 2)"/></Field> <!-- Total surcharge -->
			<Field type="integer" tag="INVSUM SUBS"><xsl:value-of select="untdi:convertToUntdiDecimal($totalSummary/Subsidy, 2)"/></Field> <!-- Total subsidy -->
			<Field type="integer" tag="INVSUM TOT2"><xsl:value-of select="untdi:convertToUntdiDecimal($totalSummary/Total2, 2)"/></Field> <!-- Total Extended amount including surcharge and discounts -->
			<Field type="integer" tag="INVSUM SDISC"><xsl:value-of select="untdi:convertToUntdiDecimal($totalSummary/SettlementDiscount, 2)"/></Field> <!-- Settlement discount -->
			<Field type="integer" tag="INVSUM TOT3"><xsl:value-of select="untdi:convertToUntdiDecimal($totalSummary/Total3, 2)"/></Field> <!-- Total after settlement discount -->
			<Field type="integer" tag="INVSUM VATA"><xsl:value-of select="untdi:convertToUntdiDecimal($totalSummary/VatAmount, 2)"/></Field> <!-- Total VAT -->
			<Field type="integer" tag="INVSUM TOT4"><xsl:value-of select="untdi:convertToUntdiDecimal($totalSummary/Total4, 2)"/></Field> <!-- Total payable excluding settlment discount inc VAT -->
			<Field type="integer" tag="INVSUM TOT5"><xsl:value-of select="untdi:convertToUntdiDecimal($totalSummary/Total5, 2)"/></Field> <!-- Total payable including settlement discount inc VAT -->			
		</TLR>
	</xsl:template>

	<!-- Write out a batch VAT summary (VRS) -->
	<xsl:template name="BatchVatSummary">
		<xsl:param name="summaries"/>

		<xsl:if test="$summaries">
			<VRS>
				<mapper:incVar name="segmentCount"/>
				<mapper:incVar name="stlCount"/>
				<Field type="integer"><xsl:value-of select="mapper:getVar('stlCount')"/></Field> <!-- Sequence -->
				<Field><xsl:value-of select="$summaries[1]/VatCode"/></Field> <!-- VAT Code -->
				<Field type="integer" tag="VRS VATP"><xsl:value-of select="untdi:convertToUntdiDecimal($summaries[1]/VatPercentage, 3)"/></Field> <!-- VAT Percentage -->
				<Field type="integer" tag="VRS VSDE"><xsl:value-of select="untdi:convertToUntdiDecimal(sum($summaries/Total2), 2)"/></Field> <!-- VSDE -->
				<Field type="integer" tag="VRS VSDI"><xsl:value-of select="untdi:convertToUntdiDecimal(sum($summaries/Total3), 2)"/></Field> <!-- VSDI -->
				<Field type="integer" tag="VRS VATA"><xsl:value-of select="untdi:convertToUntdiDecimal(sum($summaries/VatAmount), 2)"/></Field> <!-- VAT Amount payable -->
				<Field type="integer" tag="VRS VPSE"><xsl:value-of select="untdi:convertToUntdiDecimal(sum($summaries/Total4), 2)"/></Field> <!-- VPSE -->
				<Field type="integer" tag="VRS VPSI"><xsl:value-of select="untdi:convertToUntdiDecimal(sum($summaries/Total5), 2)"/></Field> <!-- VPSI -->
			</VRS>
		</xsl:if>
	</xsl:template>								

   <!--
		The BatchReferences element in the generic documents draws from
		the same two elements in the UNTDI.
   -->
	<xsl:template name="write-stx-content">
		<xsl:param name="batchReferences"/>
		<xsl:param name="hubEnvelope"/>
		<xsl:param name="hubDocument"/>
		<xsl:param name="genNumber"/>

			<Field>
				<Field><xsl:value-of select="$hubEnvelope/@syntax"/></Field> <!-- ANA or ANAA -->
				<Field>1</Field>
			</Field>
			<Field> 
				<Field> <!-- Sender ID -->
					<xsl:choose>
						<xsl:when test="string-length($SenderAnaCode) &gt; 0"><xsl:value-of select="$SenderAnaCode"/></xsl:when>
						<xsl:otherwise><xsl:value-of select="$batchReferences/SenderCode"/></xsl:otherwise>
					</xsl:choose>					
				</Field> 
				<Field><xsl:value-of select="$batchReferences/SenderName"/></Field> <!-- Sender Name -->
			</Field>
			<Field> 
				<Field><xsl:value-of select="$hubEnvelope/@ean"/></Field> <!-- Receiver ID -->
				<Field> <!-- Receiver Name -->
					<xsl:choose>
						<xsl:when test="string-length($batchReferences/ReceiverName) &gt; 0"><xsl:value-of select="$batchReferences/ReceiverName"/></xsl:when>
						<xsl:otherwise><xsl:value-of select="$hubEnvelope/@name"/></xsl:otherwise>
					</xsl:choose>					
				</Field>
			</Field>
			<Field> 
				<Field><xsl:value-of select="date:insert('yyMMdd')"/></Field> <!-- Date of Transmission -->
				<Field><xsl:value-of select="date:insert('HHmmss')"/></Field> <!-- Time of Transmission -->
			</Field>
			<Field> <!-- Ref number -->
				<xsl:choose>
					<xsl:when test="string-length($InterchangeNumberPrefix) &gt; 0"><xsl:value-of select="concat($InterchangeNumberPrefix, $genNumber)"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="$genNumber"/></xsl:otherwise>
				</xsl:choose>				
			</Field>
			<Field><xsl:value-of select="$NetworkPassword"/></Field> <!-- Password -->
			<Field> <!-- Application Reference -->
				<xsl:value-of select="$hubDocument/@app"/>
			</Field>
			<Field>B</Field> <!-- B = Normal priority -->
  </xsl:template>

	<!--
		Validate any invoice header info which is particular to a hub.
		This is to be implemented by templates which derive from this
		base template.		
	-->
	<xsl:template name="validate-invoice-header">
		<xsl:param name="hubEnvelope"/>
		<xsl:param name="hubDocument"/>
		<xsl:param name="invoice"/>
	
	</xsl:template>

	<!--
		Validate any invoice line info which is particular to a hub.
		This is to be implemented by templates which derive from this
		base template.		
	-->
	<xsl:template name="validate-invoice-line">
		<xsl:param name="hubEnvelope"/>
		<xsl:param name="hubDocument"/>
		<xsl:param name="line"/>
	
	</xsl:template>

	<!--
		Obtain the customer location code for the invoice. By default
		it will just return whatever is in the location code of the
		generic XML.
	-->
	<xsl:template name="get-customers-location-code">
		<xsl:param name="ean"/>
		<xsl:param name="customers"/>
		<xsl:param name="suppliers"/>		
		<xsl:value-of select="$customers"/>
	</xsl:template>

</xsl:stylesheet>
