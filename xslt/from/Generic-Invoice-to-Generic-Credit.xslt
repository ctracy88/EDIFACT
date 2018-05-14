<?xml version="1.0"?>
<!--
	XSLT to transform a Generic XML Invoice into a Generic XML Credit. This is useful where
	negative invoices need to be converted into credits.
	
	Input: Generic XML Invoice.
	Output: Generic XML Credit.
	
	Author: Pete Shelmerdine
	Version: 1.0
	Creation Date: 20-Jun-2006
	
	Last Modified Date: 20-Jun-2006
	Last Modified By: Pete Shelmerdine	
-->
<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:date="com.css.base.xml.xslt.ext.XsltDateExtension"
                xmlns:math="com.css.base.xml.xslt.ext.XsltMathExtension"
								xmlns:mapper="com.api.tx.MapperEngine"
                extension-element-prefixes="date mapper math">

  <xsl:output method="xml"/>

	<xsl:template match="/">
		<Batch>
			<xsl:apply-templates select="/Batch/Invoice"/>
		</Batch>
	</xsl:template>
	
	<xsl:template match="Invoice">
		<Credit>
			<xsl:attribute name="number">
				<xsl:value-of select="@number"/>
			</xsl:attribute>
			<xsl:attribute name="version">
				<xsl:value-of select="@version"/>
			</xsl:attribute>
			<xsl:attribute name="type">
				<xsl:value-of select="'Credit'"/>
			</xsl:attribute>
			<xsl:attribute name="currency">
				<xsl:value-of select="@currency"/>
			</xsl:attribute>

			<BatchReferences>
				<xsl:attribute name="test">
					<xsl:value-of select="BatchReferences/@test"/>
				</xsl:attribute>
				<Number><xsl:value-of select="BatchReferences/Number"/></Number>
				<Version><xsl:value-of select="BatchReferences/Version"/></Version>
				<Date><xsl:value-of select="BatchReferences/Date"/></Date>
				
				<SenderCode><xsl:value-of select="BatchReferences/SenderCode"/></SenderCode>
				<SenderName><xsl:value-of select="BatchReferences/SenderName"/></SenderName>
				<ReceiverCode><xsl:value-of select="BatchReferences/ReceiverCode"/></ReceiverCode>
				<ReceiverName><xsl:value-of select="BatchReferences/ReceiverName"/></ReceiverName>
				<BatchRef><xsl:value-of select="BatchReferences/BatchRef"/></BatchRef>
			</BatchReferences>
			
			<Supplier>
				<EanCode><xsl:value-of select="Supplier/EanCode"/></EanCode>
				<SuppliersCode><xsl:value-of select="Supplier/SuppliersCode"/></SuppliersCode>
				<CustomersCode><xsl:value-of select="Supplier/CustomersCode"/></CustomersCode>
				<Name><xsl:value-of select="Supplier/Name"/></Name>
				<Address>
					<Title><xsl:value-of select="Supplier/Address/Title"/></Title>
					<Street><xsl:value-of select="Supplier/Address/Street"/></Street>
					<Town><xsl:value-of select="Supplier/Address/Town"/></Town>
					<City><xsl:value-of select="Supplier/Address/City"/></City>
					<PostCode><xsl:value-of select="Supplier/Address/PostCode"/></PostCode>
				</Address>
				<VatNumber>
					<xsl:attribute name="type">
						<xsl:value-of select="Supplier/VatNumber/@type"/>
					</xsl:attribute>
					<xsl:value-of select="Supplier/VatNumber"/>
				</VatNumber>
				<FreeText><xsl:value-of select="Supplier/FreeText"/></FreeText>
			</Supplier>

			<Customer>
				<EanCode><xsl:value-of select="Customer/EanCode"/></EanCode>
				<SuppliersCode><xsl:value-of select="Customer/SuppliersCode"/></SuppliersCode>
				<CustomersCode><xsl:value-of select="Customer/CustomersCode"/></CustomersCode>
				<Name><xsl:value-of select="Customer/Name"/></Name>
				<Address>
					<Title><xsl:value-of select="Customer/Address/Title"/></Title>
					<Street><xsl:value-of select="Customer/Address/Street"/></Street>
					<Town><xsl:value-of select="Customer/Address/Town"/></Town>
					<City><xsl:value-of select="Customer/Address/City"/></City>
					<PostCode><xsl:value-of select="Customer/Address/PostCode"/></PostCode>
				</Address>
				<VatNumber>
					<xsl:attribute name="type">
						<xsl:value-of select="Customer/VatNumber/@type"/>
					</xsl:attribute>
					<xsl:value-of select="Customer/VatNumber"/>
				</VatNumber>
				<FreeText><xsl:value-of select="Customer/FreeText"/></FreeText>
			</Customer>
			
			<QueriesTo>
				<EanCode><xsl:value-of select="QueriesTo/EanCode"/></EanCode>
				<SuppliersCode><xsl:value-of select="QueriesTo/SuppliersCode"/></SuppliersCode>
				<CustomersCode><xsl:value-of select="QueriesTo/CustomersCode"/></CustomersCode>
				<Name><xsl:value-of select="QueriesTo/Name"/></Name>
				<Address>
					<Title><xsl:value-of select="QueriesTo/Address/Title"/></Title>
					<Street><xsl:value-of select="QueriesTo/Address/Street"/></Street>
					<Town><xsl:value-of select="QueriesTo/Address/Town"/></Town>
					<City><xsl:value-of select="QueriesTo/Address/City"/></City>
					<PostCode><xsl:value-of select="QueriesTo/Address/PostCode"/></PostCode>
				</Address>
				<VatNumber>
					<xsl:attribute name="type">
						<xsl:value-of select="QueriesTo/VatNumber/@type"/>
					</xsl:attribute>
					<xsl:value-of select="QueriesTo/VatNumber"/>
				</VatNumber>
				<FreeText><xsl:value-of select="QueriesTo/FreeText"/></FreeText>
			</QueriesTo>

			<DeliverTo>
				<xsl:attribute name="direct">
					<xsl:value-of select="DeliverTo/@direct"/>
				</xsl:attribute>
				<EanCode><xsl:value-of select="DeliverTo/EanCode"/></EanCode>
				<SuppliersCode><xsl:value-of select="DeliverTo/SuppliersCode"/></SuppliersCode>
				<CustomersCode><xsl:value-of select="DeliverTo/CustomersCode"/></CustomersCode>
				<Name><xsl:value-of select="DeliverTo/Name"/></Name>
				<Address>
					<Title><xsl:value-of select="DeliverTo/Address/Title"/></Title>
					<Street><xsl:value-of select="DeliverTo/Address/Street"/></Street>
					<Town><xsl:value-of select="DeliverTo/Address/Town"/></Town>
					<City><xsl:value-of select="DeliverTo/Address/City"/></City>
					<PostCode><xsl:value-of select="DeliverTo/Address/PostCode"/></PostCode>
				</Address>
				<VatNumber>
					<xsl:attribute name="type">
						<xsl:value-of select="DeliverTo/VatNumber/@type"/>
					</xsl:attribute>
					<xsl:value-of select="DeliverTo/VatNumber"/>
				</VatNumber>
				<FreeText><xsl:value-of select="DeliverTo/FreeText"/></FreeText>
			</DeliverTo>

			<xsl:if test="SettlementDiscount">
				<SettlementDiscount>
					<Terms><xsl:value-of select="SettlementDiscount/Terms"/></Terms>
					<Percentage><xsl:value-of select="SettlementDiscount/Percentage"/></Percentage>
					<ExpiresDate><xsl:value-of select="SettlementDiscount/ExpiresDate"/></ExpiresDate>
				</SettlementDiscount>
			</xsl:if>
			
			<ContractNumber><xsl:value-of select="ContractNumber"/></ContractNumber>
			<CreditDebitNumber>
				<xsl:choose>
					<xsl:when test="string-length(CreditDebitNumber) &gt; 0"><xsl:value-of select="CreditDebitNumber"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="InvoiceNumber"/></xsl:otherwise>
				</xsl:choose>				
			</CreditDebitNumber>
			<CreditDebitDate><xsl:value-of select="InvoiceDate"/></CreditDebitDate>
			<CreditDebitExpiresDate><xsl:value-of select="InvoiceExpiresDate"/></CreditDebitExpiresDate>
			<TaxPointDate><xsl:value-of select="TaxPointDate"/></TaxPointDate>
			<DebitNoteNumber>
				<xsl:value-of select="DebitNoteNumber"/>
			</DebitNoteNumber>
			<DebitNoteDate>
				<xsl:value-of select="DebitNoteDate"/>
			</DebitNoteDate>

			<InvoiceNumber>
				<xsl:choose>
					<xsl:when test="string-length(AssociatedInvoiceNumber) &gt; 0"><xsl:value-of select="AssociatedInvoiceNumber"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="InvoiceNumber"/></xsl:otherwise>
				</xsl:choose>				
			</InvoiceNumber>
			<InvoiceDate>
				<xsl:choose>
					<xsl:when test="string-length(AssociatedInvoiceDate) &gt; 0"><xsl:value-of select="AssociatedInvoiceDate"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="InvoiceDate"/></xsl:otherwise>
				</xsl:choose>				
			</InvoiceDate>
			<DeliveryDate><xsl:value-of select="DeliveryDate"/></DeliveryDate>
			<InvoiceTaxPointDate><xsl:value-of select="TaxPointDate"/></InvoiceTaxPointDate>
			
			<DeliveryNoteNumber><xsl:value-of select="DeliveryNoteNumber"/></DeliveryNoteNumber>			
			<DeliveryNoteDate><xsl:value-of select="DeliveryNoteDate"/></DeliveryNoteDate>
			<DeliveryProofNumber><xsl:value-of select="DeliveryProofNumber"/></DeliveryProofNumber>
			
			<OrderNumber>
				<Customers><xsl:value-of select="OrderNumber/Customers"/></Customers>
				<Suppliers><xsl:value-of select="OrderNumber/Suppliers"/></Suppliers>
			</OrderNumber>

			<OrderDate>
				<Customers><xsl:value-of select="OrderDate/Customers"/></Customers>
				<Suppliers><xsl:value-of select="OrderDate/Suppliers"/></Suppliers>
			</OrderDate>
			
			<xsl:apply-templates select="InvoiceLine"/>
			
			<xsl:for-each select="VatSummary">
				<VatSummary>
					<VatCode><xsl:value-of select="VatCode"/></VatCode> <!-- VATC -->
					<VatPercentage><xsl:value-of select="math:abs(VatPercentage)"/></VatPercentage> <!-- VATP -->
					<ApplicableLines><xsl:value-of select="ApplicableLines"/></ApplicableLines> <!-- NRIL Number of lines this applies to -->
					<Total1><xsl:value-of select="math:abs(Total1)"/></Total1> <!-- LVLA Excluding VAT, discounts and charges -->
					<Discount><xsl:value-of select="math:abs(Discount)"/></Discount> <!-- QYCA or VLCA -->
					<Total2><xsl:value-of select="math:abs(Total2)"/></Total2> <!-- EVLA Excluding VAT and settlement discount, including charges and discounts -->
					<SettlementDiscount><xsl:value-of select="math:abs(SettlementDiscount)"/></SettlementDiscount> <!-- SEDA -->
					<Total3><xsl:value-of select="math:abs(Total3)"/></Total3> <!-- ASDA Excluding VAT, including settlement discount, charges and discounts -->
					<VatAmount><xsl:value-of select="math:abs(VatAmount)"/></VatAmount> <!-- VATA -->
					<Total4><xsl:value-of select="math:abs(Total4)"/></Total4> <!-- APSE Excluding settlement discount, including VAT, charges and discounts -->
					<Total5><xsl:value-of select="math:abs(Total5)"/></Total5> <!-- APSI Including settlement discount, VAT, charges and discounts -->
				</VatSummary>			
			</xsl:for-each>
			
			<CreditSummary>
				<Total1><xsl:value-of select="math:abs(InvoiceSummary/Total1)"/></Total1> <!-- LVLT Excluding VAT, discounts and charges -->
				<Discount><xsl:value-of select="math:abs(InvoiceSummary/Discount)"/></Discount> <!-- QYCT or VLCT -->
				<Total2><xsl:value-of select="math:abs(InvoiceSummary/Total2)"/></Total2> <!-- EVLT Excluding VAT and settlement discount, including charges and discounts -->
				<SettlementDiscount><xsl:value-of select="math:abs(InvoiceSummary/SettlementDiscount)"/></SettlementDiscount> <!-- SEDT -->
				<Total3><xsl:value-of select="math:abs(InvoiceSummary/Total3)"/></Total3> <!-- ASDT Excluding VAT, including settlement discount, charges and discounts -->
				<VatAmount><xsl:value-of select="math:abs(InvoiceSummary/VatAmount)"/></VatAmount> <!-- TVAT -->
				<Total4><xsl:value-of select="math:abs(InvoiceSummary/Total4)"/></Total4> <!-- TPSE Excluding settlement discount, including VAT, charges and discounts -->
				<Total5><xsl:value-of select="math:abs(InvoiceSummary/Total5)"/></Total5> <!-- TPSI Including settlement discount, VAT, charges and discounts -->		
			</CreditSummary>
						
		</Credit>
	</xsl:template>


	<xsl:template match="InvoiceLine">	
		<CreditLine>
			<xsl:attribute name="debited">
				<xsl:value-of select="@debited"/>
			</xsl:attribute>
		
			<Reason>
				<xsl:choose>
					<xsl:when test="string-length(CreditReason) &gt; 0"><xsl:value-of select="CreditReason"/></xsl:when>
					<xsl:otherwise>Return</xsl:otherwise>
				</xsl:choose>
			</Reason>
			
			<Product>
				<LineNumber><xsl:value-of select="Product/LineNumber"/></LineNumber>
				<EanCode><xsl:value-of select="Product/EanCode"/></EanCode>
				<SuppliersCode><xsl:value-of select="Product/SuppliersCode"/></SuppliersCode>
				<CustomersCode><xsl:value-of select="Product/CustomersCode"/></CustomersCode>
				<PackageCode><xsl:value-of select="Product/PackageCode"/></PackageCode>
				<PalletCode><xsl:value-of select="Product/PalletCode"/></PalletCode>
				<InnerBarcode><xsl:value-of select="Product/InnerBarcode"/></InnerBarcode>
				<OtherCode><xsl:value-of select="Product/OtherCode"/></OtherCode>
				<Name><xsl:value-of select="Product/Name"/></Name>
				<FreeText><xsl:value-of select="Product/FreeText"/></FreeText>
			</Product>
			
			<Quantity>
				<AmountPerUnit><xsl:value-of select="math:abs(Quantity/AmountPerUnit)"/></AmountPerUnit>
				<Amount><xsl:value-of select="math:abs(Quantity/Amount)"/></Amount>
				<MeasureIndicator><xsl:value-of select="Quantity/MeasureIndicator"/></MeasureIndicator>
			</Quantity>
			
			<Price>
				<xsl:attribute name="currency">
					<xsl:value-of select="Price/@currency"/>
				</xsl:attribute>
				<xsl:attribute name="rate">
					<xsl:value-of select="Price/@rate"/>
				</xsl:attribute>
				<UnitPrice><xsl:value-of select="math:abs(Price/UnitPrice)"/></UnitPrice>
				<LineDiscount><xsl:value-of select="math:abs(Price/LineDiscount)"/></LineDiscount>
				<LineTotal><xsl:value-of select="math:abs(Price/LineTotal)"/></LineTotal>
			</Price>
			
			<xsl:for-each select="Vat">
				<Vat> <!-- if mixed VAT rates then we get more than one of these -->
					<Code><xsl:value-of select="Code"/></Code>
					<Percentage><xsl:value-of select="math:abs(Percentage)"/></Percentage>
					<LineVat><xsl:value-of select="math:abs(LineVat)"/></LineVat>
				</Vat>
			</xsl:for-each>
			
		</CreditLine>	
	</xsl:template>

</xsl:stylesheet>