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
			<xsl:attribute name="number"><xsl:value-of select="edi:getElement(., 1)"/></xsl:attribute>
			<xsl:attribute name="version">1</xsl:attribute>
			<xsl:attribute name="type">
				<xsl:choose>
					<xsl:when test="edi:getSubElement(., 2, 1) = 'ORDERS'">New</xsl:when>
					<xsl:when test="edi:getSubElement(., 2, 1) = 'ORDCHG'">Change</xsl:when>
					<xsl:otherwise>
						<mapper:logError>
							UNH does not define a known Order message type (ORDERS/ORDCHG): <xsl:value-of select="edi:getSubElement(., 2, 1)"/>
						</mapper:logError>					
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			
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
				<SenderName></SenderName>
				<ReceiverCode><xsl:value-of select="edi:getSubElement($envelope, 3, 1)"/></ReceiverCode>
				<ReceiverName></ReceiverName>
				<BatchRef><xsl:value-of select="edi:getElement($envelope, 5)"/></BatchRef>
			</BatchReferences>
			
			<xsl:variable name="supplier" select="NAD[Field[1] = 'SU'] | NAD[Field[1] = 'SE'] | NAD[Field[1] = 'MF']"/>
			<xsl:variable name="customer" select="NAD[Field[1] = 'BY']"/>
			<xsl:variable name="invTo" select="NAD[Field[1] = 'IV']"/>
			<xsl:variable name="delTo" select="NAD[Field[1] = 'ST'] | NAD[Field[1] = 'DP']"/>

			<xsl:if test="not($supplier)">
				<mapper:logError>
					No Supplier defined in NAD group.
				</mapper:logError>
			</xsl:if>

			<xsl:if test="not($customer)">
				<mapper:logError>
					No Customer defined in NAD group.
				</mapper:logError>
			</xsl:if>

			<xsl:if test="not($delTo)">
				<mapper:logError>
					No Delivery details defined in NAD group.
				</mapper:logError>
			</xsl:if>
			
			<Supplier>
				<EanCode>
					<xsl:value-of select="edi:getSubElement($supplier[Field[2]/Field[3] = '9' or
																	  Field[2]/Field[3] = '136'], 2, 1)"/>	<!-- 136 = GS1 UK -->
				</EanCode>
				<SuppliersCode><xsl:value-of select="edi:getSubElement($supplier[Field[2]/Field[3] = '91'], 2, 1)"/></SuppliersCode>
				<CustomersCode><xsl:value-of select="edi:getSubElement($supplier[Field[2]/Field[3] = '92'], 2, 1)"/></CustomersCode>
				<Name><xsl:value-of select="edi:getSubElement($supplier, 4, 1)"/></Name>
				<Address>
					<xsl:choose>
						<xsl:when test="string-length(edi:getSubElement($supplier, 3, 1)) &gt; 0">
							<Title><xsl:value-of select="edi:getSubElement($supplier, 3, 1)"/></Title>
							<Street><xsl:value-of select="edi:getSubElement($supplier, 3, 2)"/></Street>
							<Town><xsl:value-of select="edi:getSubElement($supplier, 3, 3)"/></Town>
							<City><xsl:value-of select="edi:getSubElement($supplier, 3, 4)"/></City>
							<PostCode><xsl:value-of select="edi:getSubElement($supplier, 3, 5)"/></PostCode>
						</xsl:when>
						<xsl:when test="string-length(edi:getSubElement($supplier, 5, 1)) &gt; 0">
							<Title><xsl:value-of select="edi:getSubElement($supplier, 5, 1)"/></Title>
							<Street><xsl:value-of select="edi:getSubElement($supplier, 5, 2)"/></Street>
							<Town><xsl:value-of select="edi:getSubElement($supplier, 5, 3)"/></Town>
							<City><xsl:value-of select="edi:getElement($supplier, 6)"/></City>
							<PostCode><xsl:value-of select="edi:getElement($supplier, 8)"/></PostCode>
						</xsl:when>
					</xsl:choose>
				</Address>
				<VatNumber/>
				<FreeText/>
			</Supplier>
		
			<Customer>
				<EanCode>
					<xsl:value-of select="edi:getSubElement($customer[Field[2]/Field[3] = '9' or
																	  Field[2]/Field[3] = '136'], 2, 1)"/>	<!-- 136 = GS1 UK -->
				</EanCode>
				<SuppliersCode><xsl:value-of select="edi:getSubElement($customer[Field[2]/Field[3] = '91'], 2, 1)"/></SuppliersCode>
				<CustomersCode><xsl:value-of select="edi:getSubElement($customer[Field[2]/Field[3] = '92'], 2, 1)"/></CustomersCode>
				<Name>
					<xsl:choose>
						<xsl:when test="string-length(edi:getSubElement($customer, 3, 1)) &gt; 0">
							<xsl:value-of select="edi:getSubElement($customer, 3, 1)"/>
						</xsl:when>
						<xsl:when test="string-length(edi:getSubElement($customer, 4, 1)) &gt; 0">
							<xsl:value-of select="edi:getSubElement($customer, 4, 1)"/>
						</xsl:when>
						<xsl:when test="string-length(edi:getSubElement($customer, 5, 1)) &gt; 0">
							<xsl:value-of select="edi:getSubElement($customer, 5, 1)"/>
						</xsl:when>
					</xsl:choose>
				</Name>
				<Address>
					<xsl:choose>
						<xsl:when test="string-length(edi:getSubElement($customer, 3, 1)) &gt; 0">
							<Title><xsl:value-of select="edi:getSubElement($customer, 3, 1)"/></Title>
							<Street><xsl:value-of select="edi:getSubElement($customer, 3, 2)"/></Street>
							<Town><xsl:value-of select="edi:getSubElement($customer, 3, 3)"/></Town>
							<City><xsl:value-of select="edi:getSubElement($customer, 3, 4)"/></City>
							<PostCode><xsl:value-of select="edi:getSubElement($customer, 3, 5)"/></PostCode>
						</xsl:when>
						<xsl:when test="string-length(edi:getSubElement($customer, 5, 1)) &gt; 0">
							<Title><xsl:value-of select="edi:getSubElement($customer, 5, 1)"/></Title>
							<Street><xsl:value-of select="edi:getSubElement($customer, 5, 2)"/></Street>
							<Town><xsl:value-of select="edi:getSubElement($customer, 5, 3)"/></Town>
							<City><xsl:value-of select="edi:getElement($customer, 6)"/></City>
							<PostCode><xsl:value-of select="edi:getElement($customer, 8)"/></PostCode>
						</xsl:when>
					</xsl:choose>
				</Address>
				<VatNumber/>
				<FreeText/>
			</Customer>

			<xsl:if test="$invTo">
				<InvoiceTo>
					<EanCode>
						<xsl:value-of select="edi:getSubElement($invTo[1][Field[2]/Field[3] = '9'or
																		  Field[2]/Field[3] = '136'], 2, 1)"/>	<!-- 136 = GS1 UK -->
					</EanCode>
					<SuppliersCode><xsl:value-of select="edi:getSubElement($invTo[1][Field[2]/Field[3] = '91'], 2, 1)"/></SuppliersCode>
					<CustomersCode><xsl:value-of select="edi:getSubElement($invTo[1][Field[2]/Field[3] = '92'], 2, 1)"/></CustomersCode>
					<Name><xsl:value-of select="edi:getSubElement($invTo[1], 4, 1)"/></Name>
					<Address>
					<xsl:choose>
						<xsl:when test="string-length(edi:getSubElement($invTo[1], 3, 1)) &gt; 0">
							<Title><xsl:value-of select="edi:getSubElement($invTo[1], 3, 1)"/></Title>
							<Street><xsl:value-of select="edi:getSubElement($invTo[1], 3, 2)"/></Street>
							<Town><xsl:value-of select="edi:getSubElement($invTo[1], 3, 3)"/></Town>
							<City><xsl:value-of select="edi:getSubElement($invTo[1], 3, 4)"/></City>
							<PostCode><xsl:value-of select="edi:getSubElement($invTo[1], 3, 5)"/></PostCode>
						</xsl:when>
						<xsl:when test="string-length(edi:getSubElement($invTo[1], 5, 1)) &gt; 0">
							<Title><xsl:value-of select="edi:getSubElement($invTo[1], 5, 1)"/></Title>
							<Street><xsl:value-of select="edi:getSubElement($invTo[1], 5, 2)"/></Street>
							<Town><xsl:value-of select="edi:getSubElement($invTo[1], 5, 3)"/></Town>
							<City><xsl:value-of select="edi:getElement($invTo[1], 6)"/></City>
							<PostCode><xsl:value-of select="edi:getElement($invTo[1], 8)"/></PostCode>
						</xsl:when>
					</xsl:choose>
					</Address>
					<VatNumber/>
					<FreeText/>
				</InvoiceTo>
			</xsl:if>

			<DeliverTo>
				<xsl:attribute name="direct">
					<xsl:choose>
						<xsl:when test="edi:getSubElement(TOD, 3, 1) = 'DDP'">true</xsl:when>
						<xsl:otherwise>false</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
				<EanCode>
					<xsl:value-of select="edi:getSubElement($delTo[1][Field[2]/Field[3] = '9' or
																	  Field[2]/Field[3] = '136'], 2, 1)"/>	<!-- 136 = GS1 UK -->
				</EanCode>
				<SuppliersCode>
					<xsl:choose>
						<xsl:when test="string-length(edi:getSubElement($delTo[1][Field[2]/Field[3] = '91'], 2, 1)) &gt; 0">
							<xsl:value-of select="edi:getSubElement($delTo[1][Field[2]/Field[3] = '91'], 2, 1)"/>
						</xsl:when>
						<!-- Amazon sometimes use an RFF+CR:ACC CODE for customer's code for location -->
						<xsl:when test="RFF/Field[1]/Field[1] = 'CR'">
							<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'CR'], 1, 2)"/>
						</xsl:when>
						<!-- Amazon use an RFF+ADE:ACC TYPE for customer's code for location -->
						<xsl:when test="RFF/Field[1]/Field[1] = 'ADE'">
							<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'ADE'], 1, 2)"/>
						</xsl:when>
					</xsl:choose>
				</SuppliersCode>
				<CustomersCode>
					<xsl:value-of select="edi:getSubElement($delTo[1][Field[2]/Field[3] = '92'], 2, 1)"/>
				</CustomersCode>
				<Name><xsl:value-of select="edi:getSubElement($delTo[1], 4, 1)"/></Name>
				<Address>
					<xsl:choose>
						<xsl:when test="$delTo[1]/Field[3]/Field[1]">
							<Title><xsl:value-of select="edi:getSubElement($delTo[1], 3, 1)"/></Title>
							<Street><xsl:value-of select="edi:getSubElement($delTo[1], 3, 2)"/></Street>
							<Town><xsl:value-of select="edi:getSubElement($delTo[1], 3, 3)"/></Town>
							<City><xsl:value-of select="edi:getSubElement($delTo[1], 3, 4)"/></City>
							<PostCode><xsl:value-of select="edi:getSubElement($delTo[1], 3, 5)"/></PostCode>
						</xsl:when>
						<xsl:when test="$delTo[1]/Field[4]/Field[1]">
							<Title><xsl:value-of select="edi:getSubElement($delTo[1], 4, 1)"/></Title>
							<Street><xsl:value-of select="edi:getSubElement($delTo[1], 4, 2)"/></Street>
							<Town><xsl:value-of select="edi:getSubElement($delTo[1], 4, 3)"/></Town>
							<City><xsl:value-of select="edi:getSubElement($delTo[1], 4, 4)"/></City>
							<PostCode><xsl:value-of select="edi:getSubElement($delTo[1], 4, 5)"/></PostCode>
						</xsl:when>
						<xsl:otherwise>
							<Title><xsl:value-of select="edi:getSubElement($delTo[1], 5, 1)"/></Title>
							<Street><xsl:value-of select="edi:getSubElement($delTo[1], 5, 2)"/></Street>
							<Town><xsl:value-of select="edi:getSubElement($delTo[1], 5, 3)"/></Town>
							<City><xsl:value-of select="edi:getElement($delTo[1], 6)"/></City>
							<PostCode><xsl:value-of select="edi:getElement($delTo[1], 8)"/></PostCode>
						</xsl:otherwise>
					</xsl:choose>
				</Address>
				<VatNumber/>
				<xsl:for-each select="FTX[Field[1] = 'COI']">
					<FreeText><xsl:value-of select="edi:getSubElement(., 4, 1)"/></FreeText>
					<FreeText><xsl:value-of select="edi:getSubElement(., 4, 2)"/></FreeText>
					<FreeText><xsl:value-of select="edi:getSubElement(., 4, 3)"/></FreeText>
					<FreeText><xsl:value-of select="edi:getSubElement(., 4, 4)"/></FreeText>
					<FreeText><xsl:value-of select="edi:getSubElement(., 4, 5)"/></FreeText>
				</xsl:for-each>
			</DeliverTo>

			<OrderNumber>
				<Customers>
					<xsl:choose>
						<xsl:when test="RFF[Field[1]/Field[1] = 'ON']">
							<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'ON'], 1, 2)"/>
						</xsl:when>
						<xsl:when test="RFF[Field[1]/Field[1] = 'OP']">
							<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'OP'], 1, 2)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="edi:getSubElement(BGM, 2, 1)"/>
						</xsl:otherwise>
					</xsl:choose>
				</Customers>
				<Suppliers/>
			</OrderNumber>

			<SpecificationNumber>
				<!-- Stick other references in here??? -->
				<xsl:choose>
					<xsl:when test="RFF/Field[1]/Field[1] = 'ADE'"> <!-- Account number -->
						<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'ADE'], 1, 2)"/>
					</xsl:when>
				</xsl:choose>
			</SpecificationNumber>
			<ContractNumber/>

			<Payment>
				<Terms><xsl:value-of select="edi:getSubElement(FTX[Field[1] = 'AAB'], 4, 1)"/></Terms>
				<Instructions><xsl:value-of select="edi:getSubElement(FTX[Field[1] = 'PAY'], 4, 1)"/></Instructions>
			</Payment>

			<OrderDate> <!-- YYYY-MM-DD -->
				<Customers>
					<xsl:if test="DTM[Field[1]/Field[1] = '137']">
						<date:reformat curFormat="yyyyMMdd" newFormat="yyyy-MM-dd">
							<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '137'], 1, 2)"/>
						</date:reformat>						
					</xsl:if>
				</Customers>
				<Suppliers></Suppliers>
			</OrderDate>
		
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

			<xsl:if test="CUX and edi:getSubElement(CUX, 1, 2) != 'GBP'">
				<mapper:logWarning>
					Currency is not GBP. This is not supported: <xsl:value-of select="edi:getSubElement(CUX, 1, 2)"/>
				</mapper:logWarning>
			</xsl:if>
			
			<!-- do the order lines -->
			<xsl:apply-templates select="LIN"/>
			
		</PurchaseOrder>
	
	</xsl:template>


	<!--
		Process an order line.
	-->
	<xsl:template match="LIN">
	
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
				<MeasureIndicator>Each</MeasureIndicator>
			</Quantity>

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
