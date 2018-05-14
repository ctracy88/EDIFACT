<?xml version="1.0"?>
<!--
	XSLT to transform an Edifact Purchase Order message into a Generix XML variation.
	
	Input: EDIFACT D93A/D96A/D97A ORDER.
	Output: Generic XML Order.
	
	Author: Pete Shelmerdine
	Version: 1.0
	Creation Date: 02-May-2006
	
	Last Modified Date: 02-May-2006
	Last Modified By: Pete Shelmerdine
-->
<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"				
                xmlns:date="com.css.base.xml.xslt.ext.XsltDateExtension"
                xmlns:math="com.css.base.xml.xslt.ext.XsltMathExtension"
                xmlns:edi="com.css.base.xml.xslt.ext.edi.XsltParsedEdifactEdiExtension"
                xmlns:file="com.css.base.xml.xslt.ext.XsltFileExtension"
		xmlns:mapper="com.api.tx.MapperEngine"
                extension-element-prefixes="date math mapper edi file">
                
	<xsl:output method="xml"/>

	<xsl:param name="Outbox"/>

  <xsl:template match="/">
		<xsl:if test="count(/Document/UNB) &gt; 1">
			<mapper:logError>
				Multiple envelopes is Unsupported.
			</mapper:logError>
		</xsl:if>
		
		<xsl:variable name="filename">
			<xsl:value-of select="concat(mapper:getVar('$$SourceFile'), '.', position(), '.order.xml')"/>
		</xsl:variable>

		<!-- This will ensure it is deleted if an error occurs -->
		<mapper:registerCreatedFile>
			<xsl:value-of select="concat($Outbox, '/', $filename)"/>
		</mapper:registerCreatedFile>

		<file:save name="$filename" path="$Outbox" append="false" returnData="false" type="xml">
		<Batch>
			<xsl:apply-templates select="/Document/UNB/UNH | /Document/UNB/UNG/UNH">
				<xsl:with-param name="envelope" select="/Document/UNB"/>
			</xsl:apply-templates>
		</Batch>
		</file:save>
	</xsl:template>


	<xsl:template match="UNH">
		<xsl:param name="envelope"/>

		<PurchaseOrder>
			<BatchReferences>
				<xsl:attribute name="test">
					<xsl:choose>
						<xsl:when test="edi:getElement($envelope, 11) = '1'">true</xsl:when>
						<xsl:otherwise>false</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
				
				<Number><xsl:value-of select="edi:getElement(., 1)"/></Number>
				<Version>1</Version>
				<Date>
					<date:reformat curFormat="yyMMdd" newFormat="yyyy-MM-dd">
						<xsl:value-of select="edi:getSubElement($envelope, 4, 1)"/>
					</date:reformat>
				</Date>
				
				<SenderCode><xsl:value-of select="edi:getSubElement($envelope, 2, 1)"/></SenderCode>
				<SenderCodeQualifier><xsl:value-of select="edi:getSubElement($envelope, 2, 2)"/></SenderCodeQualifier>
				<SenderName></SenderName>
				<ReceiverCode><xsl:value-of select="edi:getSubElement($envelope, 3, 1)"/></ReceiverCode>
				<ReceiverCodeQualifier><xsl:value-of select="edi:getSubElement($envelope, 3, 2)"/></ReceiverCodeQualifier>
				<ReceiverName></ReceiverName>
				<BatchRef><xsl:value-of select="edi:getElement($envelope, 5)"/></BatchRef>
			</BatchReferences>
			<TransactionType>
				<xsl:value-of select="edi:getSubElement(BGM, 1, 1)"/>
			</TransactionType>
			<PONumber>
				<xsl:value-of select="edi:getSubElement(BGM, 2, 1)"/>
			</PONumber>
			<Purpose>
				<xsl:value-of select="edi:getElement(BGM, 3)"/>
			</Purpose>
			<DTM>
				<DocDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '137'], 1, 2)"/>
				</DocDate>
				<RequestedDeliveryDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '2'], 1, 2)"/>
				</RequestedDeliveryDate>
			</DTM>
			<RFF>
				<CustomerRefNum>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'CR'], 1, 2)"/>
				</CustomerRefNum>
				<PromotionNum>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'PD'], 1, 2)"/>
				</PromotionNum>
				<BusinessFormat>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'ZZZ'], 1, 2)"/>
				</BusinessFormat>
			</RFF>
			<!-- Start of NADs></!-->
			<xsl:variable name="buyer" select="NAD[Field[1] = 'BY']"/>
			<xsl:variable name="broker" select="NAD[Field[1] = 'DP']"/>
			<xsl:variable name="supplier" select="NAD[Field[1] = 'SU']"/>
			
			
			<BuyingParty>
				<Code>
					<xsl:value-of select="edi:getSubElement($BuyingParty, 2, 1)"/>
				</Code>
				<CodeType>
					<xsl:value-of select="edi:getSubElement($BuyingParty, 2, 2)"/>
				</CodeType>
				<Name>
					<xsl:value-of select="edi:getSubElement($BuyingParty, 3, 1)"/>
				</Name>
				<Address1>
					<xsl:value-of select="edi:getSubElement($BuyingParty, 5, 1)"/>
				</Address1>
				<Address2>
					<xsl:value-of select="edi:getSubElement($BuyingParty, 5, 2)"/>
				</Address2>
				<City>
					<xsl:value-of select="edi:getElement($BuyingParty, 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getSubElement($BuyingParty, 7, 1)"/>
				</State>
				<ZipCode>
					<xsl:value-of select="edi:getElement($BuyingParty, 8)"/>
				</ZipCode>
				<Country>
					<xsl:value-of select="edi:getElement($BuyingParty, 9)"/>
				</Country>
				<CTA>
					<ContactName>
						<xsl:value-of select="edi:getSubElement($BuyingParty/CTA[Field[1] = 'OC'], 2, 2)"/>
					</ContactName>
					<COM>
						<ContactEmail>
							<xsl:value-of select="edi:getSubElement($BuyingParty/CTA/COM[Field[2]/Field[1] = 'EM'], 1, 1)"/>
						</ContactEmail>
					</COM>
				</CTA>
			</BuyingParty>
			<Broker>
				<Code>
					<xsl:value-of select="edi:getSubElement($broker, 2, 1)"/>
				</Code>
				<CodeType>
					<xsl:value-of select="edi:getSubElement($broker, 2, 2)"/>
				</CodeType>
				<Name>
					<xsl:value-of select="edi:getSubElement($broker, 3, 1)"/>
				</Name>
				<Address1>
					<xsl:value-of select="edi:getSubElement($broker, 5, 1)"/>
				</Address1>
				<Address2>
					<xsl:value-of select="edi:getSubElement($broker, 5, 2)"/>
				</Address2>
				<City>
					<xsl:value-of select="edi:getElement($broker, 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getSubElement($broker, 7, 1)"/>
				</State>
				<ZipCode>
					<xsl:value-of select="edi:getElement($broker, 8)"/>
				</ZipCode>
				<Country>
					<xsl:value-of select="edi:getElement($broker, 9)"/>
				</Country>
			</Broker>
			<Supplier>
				<Code>
					<xsl:value-of select="edi:getSubElement($supplier, 2, 1)"/>
				</Code>
				<Name>
					<xsl:value-of select="edi:getSubElement($supplier, 3, 1)"/>
				</Name>
				<Address1>
					<xsl:value-of select="edi:getSubElement($supplier, 5, 1)"/>
				</Address1>
				<Address2>
					<xsl:value-of select="edi:getSubElement($supplier, 5, 2)"/>
				</Address2>
				<City>
					<xsl:value-of select="edi:getElement($supplier, 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getSubElement($supplier, 7, 1)"/>
				</State>
				<ZipCode>
					<xsl:value-of select="edi:getElement($supplier, 8)"/>
				</ZipCode>
				<Country>
					<xsl:value-of select="edi:getElement($supplier, 9)"/>
				</Country>
				<RFF>
					<xsl:value-of select="edi:getSubElement($supplier/RFF[Field[1]/Field[1] = 'VA'], 1, 2)"/>
				</RFF>
				<CTA>
					<ContactName>
						<xsl:value-of select="edi:getSubElement($supplier/CTA[Field[1] = 'DL'], 2, 2)"/>
					</ContactName>
					<COM>
						<ContactEmail>
							<xsl:value-of select="edi:getSubElement($supplier/CTA/COM[Field[2]/Field[1] = 'EM'], 1, 1)"/>
						</ContactEmail>
					</COM>
				</CTA>
			</Supplier>
			
			<!--END NADs -->	
			
			<CUX>
				<CurrencyType>
					<xsl:value-of select="edi:getSubElement(CUX, 1, 1)"/>
				</CurrencyType>
				<Currency>
					<xsl:value-of select="edi:getSubElement(CUX, 1, 2)"/>
				</Currency>
			</CUX>
			
			
			<xsl:apply-templates select="LIN"/>
			
		</PurchaseOrder>
		
		
	
	</xsl:template>

	<xsl:template match="LIN">
		<Items>
			<LIN>
				<LineNum>
					<xsl:value-of select="edi:getElement(self::node(), 1)"/>
				</LineNum>
				<EANNum>
					<xsl:value-of select="edi:getSubElement(self::node()[Field[3]/Field[2] = 'EN'], 3, 1)"/>
				</EANNum>
				<BuyersItemNum>
					<xsl:value-of select="edi:getSubElement(PIA[Field[2]/Field[2] = 'IN'], 2, 1)"/>
				</BuyersItemNum>
				<SuppliersArticleNum>
					<xsl:value-of select="edi:getSubElement(PIA[Field[2]/Field[2] = 'SA'], 2, 1)"/>
				</SuppliersArticleNum>
				<PromotionalVariantNum>
					<xsl:value-of select="edi:getSubElement(PIA[Field[2]/Field[2] = 'GN'], 2, 1)"/>
				</PromotionalVariantNum>
				<Description>
					<xsl:value-of select="edi:getSubElement(IMD, 3, 4)"/>
				</Description>
			</LIN>
			<QTY>
				<QtyOrdered>
					<xsl:value-of select="edi:getSubElement(QTY[Field[1]/Field[1] = '21'], 1, 2)"/>
				</QtyOrdered>
			</QTY>
			<FTX>
				<xsl:for-each select="FTX">
					<Note><xsl:value-of select="edi:getSubElement(., 4, 1)"/></Note>
					<Note><xsl:value-of select="edi:getSubElement(., 4, 2)"/></Note>
					<Note><xsl:value-of select="edi:getSubElement(., 4, 3)"/></Note>
					<Note><xsl:value-of select="edi:getSubElement(., 4, 4)"/></Note>
					<Note><xsl:value-of select="edi:getSubElement(., 4, 5)"/></Note>
				</xsl:for-each>
			</FTX>
			<PRI>
				<Price>
					<xsl:value-of select="edi:getSubElement(PRI[Field[1]/Field[1] = 'AAA'], 1, 2)"/>
				</Price>
			</PRI>
			<RFF>
				<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'PD'], 1, 2)"/>
			</RFF>
			
		</Items>
	</xsl:template>
	<!--
		Process an order line.
	-->
	<xsl:template match="OLDLIN">
	
		<!--
			LIN element 2 (Action Coded)...
			
      1 Added
            This line item is added to the referenced message.
      2 Deleted
            This line item is deleted from the referenced message.
      3 Changed
            This line item is changed in the referenced message.
      4 No action
            This line item is not affected by the actual message.
      5 Accepted without amendment
            This line item is entirely accepted by the seller.
      6 Accepted with amendment
            This line item is accepted but amended by the seller.
      7 Not accepted
            This line item is not accepted by the seller.
      8 Schedule only
            Self explanatory.
      9 Amendments
            Self explanatory.
      10 Not found
            This line item is not found in the referenced message.
      11 Not amended
            This line is not amended by the buyer.
      12 Line item numbers changed
            Self explanatory.
      13 Buyer has deducted amount
            Buyer has deducted amount from payment.
      14 Buyer claims against invoice
            Buyer has a claim against an outstanding invoice.
      15 Charge back by seller
            Factor has been requested to charge back the outstanding
            item.
      16 Seller will issue credit note
            Seller agrees to issue a credit note.
      17 Terms changed for new terms
            New settlement terms have been agreed.
      18 Abide outcome of negotiations
            Factor agrees to abide by the outcome of negotiations
            between seller and buyer.
      19 Seller rejects dispute
            Seller does not accept validity of dispute.
      20 Settlement
            The reported situation is settled.
      21 No delivery
            Code indicating that no delivery will be required.
      22 Call-off delivery
            A request for delivery of a particular quantity of goods
            to be delivered on a particular date (or within a
            particular period).
      23 Proposed amendment
            A code used to indicate an amendment suggested by the
            sender.
      24 Accepted with amendment, no confirmation required
            Accepted with changes which require no confirmation.
		-->

	
	</xsl:template>

</xsl:stylesheet>
