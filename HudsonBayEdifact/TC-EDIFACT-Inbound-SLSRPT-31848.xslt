<?xml version="1.0"?>
<!--
	XSLT to transform Hudson Bay Edifact ORDERS message into TC XML variation.
	
	Input: Hudson Bay Edifact EDIFACT D01B ORDER.
	Output: TC XML Order.
	
	Author: Jen Ciambro
	Version: 1.0
	Creation Date: August 4, 2017
	
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
		<BGM>
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
				<AckRequested><xsl:value-of select="edi:getElement($envelope, 9)"/></AckRequested>
			</BatchReferences>
			<TransactionType>
				<xsl:value-of select="edi:getSubElement(BGM, 1, 1)"/>
			</TransactionType>
			<Agency>
				<xsl:value-of select="edi:getSubElement(BGM, 1, 3)"/>
			</Agency>
			<SalesDataReportNum>
				<xsl:value-of select="edi:getSubElement(BGM, 2, 1)"/>
			</SalesDataReportNum>
			<Purpose>
				<xsl:value-of select="edi:getElement(BGM, 3)"/>
			</Purpose>
			<DTM>
				<DocDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '137'], 1, 2)"/>
				</DocDate>
				<StartDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '90'], 1, 2)"/>
				</StartDate>
				<EndDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '91'], 1, 2)"/>
				</EndDate>
			</DTM>
			<!-- Start of NADs></!-->
			<xsl:variable name="NAD.BY" select="NAD[Field[1] = 'BY']"/>
			<xsl:variable name="NAD.CO" select="NAD[Field[1] = 'CO']"/>
			<xsl:variable name="supplier" select="NAD[Field[1] = 'SU']"/>
			<NAD.BY>
				<Code>
					<xsl:value-of select="edi:getSubElement($NAD.BY, 2, 1)"/>
				</Code>
				<CodeType>
					<xsl:value-of select="edi:getSubElement($NAD.BY, 2, 3)"/>
				</CodeType>
			</NAD.BY>
			<NAD.CO>
				<Code>
					<xsl:value-of select="edi:getSubElement($NAD.CO, 2, 1)"/>
				</Code>
				<CodeType>
					<xsl:value-of select="edi:getSubElement($NAD.CO, 2, 3)"/>
				</CodeType>
				<CTA>
					<CorporateContact>
						<xsl:value-of select="edi:getSubElement($supplier/CTA[Field[1]/Field[1] = 'PD'], 2, 1)"/>
					</CorporateContact>
				</CTA>
			</NAD.CO>
			<Supplier>
				<Code>
					<xsl:value-of select="edi:getSubElement($supplier, 2, 1)"/>
				</Code>
				<CodeType>
					<xsl:value-of select="edi:getSubElement($supplier, 2, 3)"/>
				</CodeType>
			</Supplier>
			<!--END NADs -->	
			<CUX>
				<CurrencyType>
					<xsl:value-of select="edi:getSubElement(CUX, 1, 1)"/>
				</CurrencyType>
				<Currency>
					<xsl:value-of select="edi:getSubElement(CUX, 1, 2)"/>
				</Currency>
				<CurrencyTypeCode>
					<xsl:value-of select="edi:getSubElement(CUX, 1, 3)"/>
				</CurrencyTypeCode>
			</CUX>
			<LOC>
				<LocationType>
					<xsl:value-of select="edi:getSubElement(LOC, 1, 1)"/>
				</LocationType>
				<Location>
					<xsl:value-of select="edi:getSubElement(LOC, 2, 1)"/>
				</Location>
				<LocationCodeType>
					<xsl:value-of select="edi:getSubElement(LOC, 2, 3)"/>
				</LocationCodeType>
				<DTM>
					<SalesDate>
						<xsl:value-of select="edi:getSubElement(LOC/DTM[Field[1]/Field[1] = '137'], 1, 2)"/>
					</SalesDate>
				</DTM>
			</LOC>
			<!-- do the order lines -->
			<xsl:apply-templates select="LIN"/>
			<MOA>
				<TotalAmt>
					<xsl:value-of select="edi:getSubElement(MOA[Field[1]/Field[1] = '86'], 1, 2)"/>
				</TotalAmt>
			</MOA>
		</BGM>
	</xsl:template>
	<xsl:template match="LIN">
		<Items>
			<LIN>
				<LineNum>
					<xsl:value-of select="edi:getElement(self::node(), 1)"/>
				</LineNum>
				<GTINNum>
					<xsl:value-of select="edi:getSubElement(self::node()[Field[3]/Field[2] = 'SRV'], 3, 1)"/>
				</GTINNum>
			</LIN>
			<RFF>
				<SellerReferenceNum>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'SS'], 1, 2)"/>
				</SellerReferenceNum>
			</RFF>
			<MOA>
				<LineItemAmount>
					<xsl:value-of select="edi:getSubElement(MOA[Field[1]/Field[1] = '203'], 1, 2)"/>
				</LineItemAmount>
				<ChargeAllowanceBasis>
					<xsl:value-of select="edi:getSubElement(MOA[Field[1]/Field[1] = '25'], 1, 2)"/>
				</ChargeAllowanceBasis>
			</MOA>
			<PRI>
				<RetailPrice>
					<xsl:value-of select="edi:getSubElement(PRI[Field[1]/Field[1] = 'AAB'], 1, 2)"/>
				</RetailPrice>
				<RetailPriceBasis>
					<xsl:value-of select="edi:getSubElement(PRI[Field[1]/Field[1] = 'AAB'], 1, 5)"/>
				</RetailPriceBasis>
			</PRI>
			<QTY>
				<QtyOrdered>
					<xsl:value-of select="edi:getSubElement(QTY[Field[1]/Field[1] = '153'], 1, 2)"/>
				</QtyOrdered>
			</QTY>
			<xsl:variable name="NAD" select="NAD[Field[1] = 'X47']"/>
			<NAD>
				<Code>
					<xsl:value-of select="edi:getSubElement(NAD, 2, 1)"/>
				</Code>
			</NAD>
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
	
		<OrderLine>
			<xsl:attribute name="action">
				<xsl:variable name="code" select="Field[2]"/>
				<xsl:choose>
					<xsl:when test="$code = '1'">Add</xsl:when>
					<xsl:when test="$code = '2'">Delete</xsl:when>
					<xsl:when test="$code = '3'">Change</xsl:when>
					<xsl:when test="string-length($code) = 0">Add</xsl:when>
					<xsl:otherwise>
						<mapper:logError>
							Unsupported action code in LIN: <xsl:value-of select="$code"/>
						</mapper:logError>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
		
			<!-- Product info can come in from LIN or PIA -->
			<Product>
				<LineNumber><xsl:value-of select="position()"/></LineNumber>
				<EanCode> <!-- EAN (13 digits) or UPC (12 digits) code -->
          <xsl:choose>
            <xsl:when test="Field[3]/Field[2] = 'EN'">
              <xsl:value-of select="self::node()[Field[3]/Field[2] = 'EN']/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="Field[3]/Field[2] = 'UP'">
              <xsl:value-of select="self::node()[Field[3]/Field[2] = 'UP']/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[2]/Field[4] = 9">
              <xsl:value-of select="PIA[Field[2]/Field[4] = 9]/Field[2]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[2]/Field[2] = 'EN'">
              <xsl:value-of select="PIA[Field[2]/Field[2] = 'EN']/Field[2]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[2]/Field[2] = 'UP'">
              <xsl:value-of select="PIA[Field[2]/Field[2] = 'UP']/Field[2]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[3]/Field[4] = 9">
              <xsl:value-of select="PIA[Field[3]/Field[4] = 9]/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[3]/Field[2] = 'EN'">
              <xsl:value-of select="PIA[Field[3]/Field[2] = 'EN']/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[3]/Field[2] = 'UP'">
              <xsl:value-of select="PIA[Field[3]/Field[2] = 'UP']/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[4]/Field[4] = 9">
              <xsl:value-of select="PIA[Field[4]/Field[4] = 9]/Field[4]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[4]/Field[2] = 'EN'">
              <xsl:value-of select="PIA[Field[4]/Field[2] = 'EN']/Field[4]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[4]/Field[2] = 'UP'">
              <xsl:value-of select="PIA[Field[4]/Field[2] = 'UP']/Field[4]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[5]/Field[4] = 9">
              <xsl:value-of select="PIA[Field[5]/Field[4] = 9]/Field[5]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[5]/Field[2] = 'EN'">
              <xsl:value-of select="PIA[Field[5]/Field[2] = 'EN']/Field[5]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[5]/Field[2] = 'UP'">
              <xsl:value-of select="PIA[Field[5]/Field[2] = 'UP']/Field[5]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[6]/Field[4] = 9">
              <xsl:value-of select="PIA[Field[6]/Field[4] = 9]/Field[6]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[6]/Field[2] = 'EN'">
              <xsl:value-of select="PIA[Field[6]/Field[2] = 'EN']/Field[6]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[6]/Field[2] = 'UP'">
              <xsl:value-of select="PIA[Field[6]/Field[2] = 'UP']/Field[6]/Field[1]"/>
            </xsl:when>
            <xsl:when test="Field[3]/Field[4] = 9">
              <xsl:value-of select="Field[3]/Field[1]"/>
            </xsl:when>
          </xsl:choose>
        </EanCode>
				<SuppliersCode>
          <xsl:choose>
            <xsl:when test="Field[3]/Field[2] = 'SA'">
              <xsl:value-of select="self::node()[Field[3]/Field[2] = 'SA']/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[2]/Field[4] = 91">
              <xsl:value-of select="PIA[Field[2]/Field[4] = 91]/Field[2]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[2]/Field[2] = 'SA'">
              <xsl:value-of select="PIA[Field[2]/Field[2] = 'SA']/Field[2]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[3]/Field[4] = 91">
              <xsl:value-of select="PIA[Field[3]/Field[4] = 91]/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[3]/Field[2] = 'SA'">
              <xsl:value-of select="PIA[Field[3]/Field[2] = 'SA']/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[4]/Field[2] = 'SA'">
              <xsl:value-of select="PIA[Field[4]/Field[2] = 'SA']/Field[4]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[4]/Field[4] = 91">
              <xsl:value-of select="PIA[Field[4]/Field[4] = 91]/Field[4]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[5]/Field[4] = 91">
              <xsl:value-of select="PIA[Field[5]/Field[4] = 91]/Field[5]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[5]/Field[2] = 'SA'">
              <xsl:value-of select="PIA[Field[5]/Field[2] = 'SA']/Field[5]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[6]/Field[2] = 'SA'">
              <xsl:value-of select="PIA[Field[6]/Field[2] = 'SA']/Field[6]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[6]/Field[4] = 91">
              <xsl:value-of select="PIA[Field[6]/Field[4] = 91]/Field[6]/Field[1]"/>
            </xsl:when>
            <xsl:when test="Field[3]/Field[4] = 91">
              <xsl:value-of select="Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[2]/Field[2] = 'IB'">
              <!-- ISBN so put it in Suppliers and Customers code -->
              <xsl:value-of select="PIA[Field[2]/Field[2] = 'IB']/Field[2]/Field[1]"/>
            </xsl:when>
          </xsl:choose>
        </SuppliersCode>
				<CustomersCode>
          <xsl:choose>
            <xsl:when test="Field[3]/Field[2] = 'IN'">
              <xsl:value-of select="self::node()[Field[3]/Field[2] = 'IN']/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="Field[3]/Field[2] = 'BP'">
              <xsl:value-of select="self::node()[Field[3]/Field[2] = 'BP']/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[2]/Field[4] = 92">
              <xsl:value-of select="PIA[Field[2]/Field[4] = 92]/Field[2]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[2]/Field[2] = 'IN'">
              <xsl:value-of select="PIA[Field[2]/Field[2] = 'IN']/Field[2]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[2]/Field[2] = 'BP'">
              <xsl:value-of select="PIA[Field[2]/Field[2] = 'BP']/Field[2]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[3]/Field[4] = 92">
              <xsl:value-of select="PIA[Field[3]/Field[4] = 92]/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[3]/Field[2] = 'IN'">
              <xsl:value-of select="PIA[Field[3]/Field[2] = 'IN']/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[3]/Field[2] = 'BP'">
              <xsl:value-of select="PIA[Field[3]/Field[2] = 'BP']/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[4]/Field[4] = 92">
              <xsl:value-of select="PIA[Field[4]/Field[4] = 92]/Field[4]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[4]/Field[2] = 'IN'">
              <xsl:value-of select="PIA[Field[4]/Field[2] = 'IN']/Field[4]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[4]/Field[2] = 'BP'">
              <xsl:value-of select="PIA[Field[4]/Field[2] = 'BP']/Field[4]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[5]/Field[4] = 92">
              <xsl:value-of select="PIA[Field[5]/Field[4] = 92]/Field[5]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[5]/Field[2] = 'IN'">
              <xsl:value-of select="PIA[Field[5]/Field[2] = 'IN']/Field[5]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[5]/Field[2] = 'BP'">
              <xsl:value-of select="PIA[Field[5]/Field[2] = 'BP']/Field[5]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[6]/Field[4] = 92">
              <xsl:value-of select="PIA[Field[6]/Field[4] = 92]/Field[6]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[6]/Field[2] = 'IN'">
              <xsl:value-of select="PIA[Field[6]/Field[2] = 'IN']/Field[6]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[6]/Field[2] = 'BP'">
              <xsl:value-of select="PIA[Field[6]/Field[2] = 'BP']/Field[6]/Field[1]"/>
            </xsl:when>
            <xsl:when test="Field[3]/Field[4] = 92">
              <xsl:value-of select="Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[2]/Field[2] = 'IB'">
              <!--  ISBN so put it in Suppliers and Customers code -->
              <xsl:value-of select="PIA[Field[2]/Field[2] = 'IB']/Field[2]/Field[1]"/>
            </xsl:when>
          </xsl:choose>
        </CustomersCode>
				<PalletCode/>
				<OtherCode><xsl:value-of select="self::node()[Field[3]/Field[2] = 'ZZZ']/Field[3]/Field[1]"/></OtherCode>
				<Name><xsl:value-of select="concat(edi:getSubElement(IMD, 3, 4), edi:getSubElement(IMD, 3, 5))"/></Name>
				<FreeText/>
			</Product>

			<Quantity>
				<AmountPerUnit><xsl:value-of select="edi:getSubElement(QTY[Field[1]/Field[1] = '59'], 1, 2)"/></AmountPerUnit>
				<Amount><xsl:value-of select="edi:getSubElement(QTY[Field[1]/Field[1] = '21'], 1, 2)"/></Amount>
				<MeasureIndicator><xsl:value-of select="edi:getSubElement(QTY, 1, 3)"/></MeasureIndicator>
			</Quantity>
			
			<DeliverBy>
				<Date> <!-- YYYY-MM-DD -->
					<xsl:if test="DTM[Field[1]/Field[1] = '64'] and DTM[Field[1]/Field[3] = '204']"> <!-- Earliest Delivery date -->
						<Earliest>
							<date:reformat curFormat="yyyyMMddHHmmss" newFormat="yyyy-MM-dd">
								<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '64'], 1, 2)"/>
							</date:reformat>						
						</Earliest>
					</xsl:if>
					<xsl:if test="DTM[Field[1]/Field[1] = '63'] and DTM[Field[1]/Field[3] = '204']"> <!-- Latest Delivery date -->
						<Latest>
							<date:reformat curFormat="yyyyMMddHHmmss" newFormat="yyyy-MM-dd">
								<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '63'], 1, 2)"/>
							</date:reformat>						
						</Latest>
					</xsl:if>
					<xsl:if test="DTM[Field[1]/Field[1] = '64']"> <!-- Earliest Delivery date -->
						<Earliest>
							<date:reformat curFormat="yyyyMMdd" newFormat="yyyy-MM-dd">
								<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '64'], 1, 2)"/>
							</date:reformat>						
						</Earliest>
					</xsl:if>
					<xsl:if test="DTM[Field[1]/Field[1] = '63']"> <!-- Latest Delivery date -->
						<Latest>
							<date:reformat curFormat="yyyyMMdd" newFormat="yyyy-MM-dd">
								<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '63'], 1, 2)"/>
							</date:reformat>						
						</Latest>
					</xsl:if>
					<xsl:if test="DTM[Field[1]/Field[1] = '2']"> <!-- Requested delivery date -->
						<Earliest>
							<date:reformat curFormat="yyyyMMdd" newFormat="yyyy-MM-dd">
								<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '2'], 1, 2)"/>
							</date:reformat>						
						</Earliest>
						<Latest>
							<date:reformat curFormat="yyyyMMdd" newFormat="yyyy-MM-dd">
								<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '2'], 1, 2)"/>
							</date:reformat>						
						</Latest>
					</xsl:if>
				</Date>
				<Time> <!-- HH:MM:SS -->
					<xsl:if test="DTM[Field[1]/Field[1] = '64'] and DTM[Field[1]/Field[3] = '204']"> <!-- Earliest Delivery date -->
						<Earliest>
							<date:reformat curFormat="yyyyMMddHHmmss" newFormat="HH:mm:ss">
								<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '64'], 1, 2)"/>
							</date:reformat>						
						</Earliest>
					</xsl:if>
					<xsl:if test="DTM[Field[1]/Field[1] = '63'] and DTM[Field[1]/Field[3] = '204']"> <!-- Latest Delivery date -->
						<Latest>
							<date:reformat curFormat="yyyyMMddHHmmss" newFormat="HH:mm:ss">
								<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '63'], 1, 2)"/>
							</date:reformat>						
						</Latest>
					</xsl:if>
				</Time>			
				<BookingReferenceNumber></BookingReferenceNumber>
				<FreeText></FreeText>
			</DeliverBy>

			<xsl:if test="PRI">
				<Price currency="GBP" rate="1.0">
					<NetUnitPrice> <!-- with discounts applied, but not multiplied by quantity -->
						<xsl:value-of select="format-number(edi:getSubElement(PRI, 1, 2), '0.0000')"/>
					</NetUnitPrice>
					<LineDiscount>0.0000</LineDiscount>
				</Price>
			</xsl:if>

		</OrderLine>
	
	</xsl:template>
</xsl:stylesheet>
