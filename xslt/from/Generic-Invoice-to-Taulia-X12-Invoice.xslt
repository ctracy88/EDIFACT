<?xml version="1.0"?>
<!--
	XSLT to transform a Generic XML Invoice into a specific Walgreens X12 invoice.
	
	Input: Generic XML Invoice.
	Output: Walgreens X12 Invoice.
	
	Author: Roy Hocknull
	Version: 1.0
	Creation Date: 16-Oct-2013
	
	Last Modified Date: 
	Last Modified By: 
-->
<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:date="com.css.base.xml.xslt.ext.XsltDateExtension"
                xmlns:math="com.css.base.xml.xslt.ext.XsltMathExtension"
                xmlns:str="com.css.base.xml.xslt.ext.XsltStringExtension"
                xmlns:edifact="com.css.base.xml.xslt.ext.edi.XsltParsedEdifactEdiExtension"
		xmlns:mapper="com.api.tx.MapperEngine"
                extension-element-prefixes="date mapper str edifact math">

    <xsl:output method="xml"/>

		<xsl:param name="Country"/> <!-- Canada or USA -->
		<xsl:param name="SenderQualifier"/>


    <xsl:template match="/">
		<xsl:apply-templates select="Batch"/>
    </xsl:template>


    <xsl:template match="Batch">
			<mapper:logMessage>
				Transforming to Taulia Ansi X12 EDI Invoices
			</mapper:logMessage>
			
			<xsl:variable name="testMode" select="/Batch/Invoice[1]/BatchReferences/@test"/>

			<xsl:variable name="GenNumber">
				<mapper:genNum>
					<xsl:value-of select="concat(/Batch/Invoice[1]/BatchReferences/SenderCode, '.', /Batch/Invoice[1]/BatchReferences/ReceiverCode, '.', 'INVOICE', '.', $testMode)"/>
				</mapper:genNum>
			</xsl:variable>

			<xsl:variable name="BatchGenNumber">
				<xsl:value-of select="str:pad($GenNumber, 5, '0', 'true')"/>
			</xsl:variable>

			<Document type="X12" wrapped="true" fieldSep="*" recSep="&#x09;">
			
				<!-- ISA. This is fixed position, hence the pad jazz -->
				<ISA>
					<Field padDir="right" padSize="2" padChar=" ">00</Field> <!-- Authorisation information qualifier -->
					<Field padDir="right" padSize="10" padChar=" "></Field> <!-- Authorisation information -->
					<Field padDir="right" padSize="2" padChar=" ">00</Field> <!-- Security information qualifier -->
					<Field padDir="right" padSize="10" padChar=" "></Field> <!-- Security information -->
					<Field padDir="right" padSize="2" padChar=" "><xsl:value-of select="$SenderQualifier"/></Field> <!-- Sender qualifier -->
					<Field padDir="right" padSize="15" padChar=" "><xsl:value-of select="Invoice[1]/BatchReferences/SenderCode"/></Field>
					<Field padDir="right" padSize="2" padChar=" "> <!-- Receiver qualifier -->
						<xsl:choose>
							<xsl:when test="$testMode = 'true'">ZZ</xsl:when>
							<xsl:otherwise>01</xsl:otherwise>
						</xsl:choose>
					</Field>
					<Field padDir="right" padSize="15" padChar=" "><xsl:value-of select="Invoice[1]/BatchReferences/ReceiverCode"/></Field>
					<Field padDir="right" padSize="6" padChar=" "><xsl:value-of select="date:insert('yyMMdd')"/></Field>
					<Field padDir="right" padSize="4" padChar=" "><xsl:value-of select="date:insert('HHmm')"/></Field>
					<Field padDir="right" padSize="1" padChar=" ">U</Field> <!-- interchange control standards ID -->
					<Field padDir="right" padSize="5" padChar=" ">00401</Field> <!-- interchange control version number -->
					<Field padDir="left" padSize="9" padChar="0"><xsl:value-of select="$BatchGenNumber"/></Field> <!-- batch number -->
					<Field padDir="right" padSize="1" padChar=" ">0</Field> <!-- Ack (997) requested, 0 or 1 -->
					<Field padDir="right" padSize="1" padChar=" "> <!-- Test indicator T = test -->
						<xsl:choose>
							<xsl:when test="$testMode = 'true'">T</xsl:when>
							<xsl:otherwise>P</xsl:otherwise>
						</xsl:choose>
					</Field>
					<Field padDir="right" padSize="1" padChar=" ">}</Field> <!-- Sub element sep -->
				</ISA>

				<!-- GS -->
				<GS>
					<Field>IN</Field> <!-- Functional ID code. IN = Invoice information -->
					<Field><xsl:value-of select="Invoice[1]/BatchReferences/SenderCode"/></Field>
					<Field><xsl:value-of select="Invoice[1]/BatchReferences/ReceiverCode"/></Field>
					<Field><xsl:value-of select="date:insert('yyyyMMdd')"/></Field>
					<Field><xsl:value-of select="date:insert('HHmm')"/></Field>
					<Field><xsl:value-of select="$BatchGenNumber"/></Field>
					<Field>X</Field> <!-- Responsibility Agency code -->
					<Field>004010</Field> <!-- Version / Rel. Ind. ID Code -->
				</GS>
			
				<mapper:setVar name="messageCount">0</mapper:setVar>				
				<xsl:apply-templates select="Invoice">
					<xsl:with-param name="batchGenNumber" select="$BatchGenNumber"/>
				</xsl:apply-templates>

				<!-- GE -->
				<GE>
					<Field><xsl:value-of select="count(Invoice)"/></Field> <!-- Number of Messages -->
					<Field><xsl:value-of select="$BatchGenNumber"/></Field> <!-- ISA batch number -->
				</GE>
				
				<!-- IEA -->
				<IEA>
					<Field>1</Field> <!-- Number of Groups -->
					<Field padDir="left" padSize="9" padChar="0"><xsl:value-of select="$BatchGenNumber"/></Field> <!-- ISA batch number -->
				</IEA>
				
			</Document>
		</xsl:template>

		
		<xsl:template match="Invoice">
			<xsl:param name="batchGenNumber"/>
			
			<!-- Invoice currency -->		
			<mapper:setVar name="currency">
				<xsl:choose>
					<xsl:when test="string-length(@currency) &gt; 0"><xsl:value-of select="@currency"/></xsl:when>
					<xsl:when test="string-length(@fromCurrency) &gt; 0"><xsl:value-of select="@fromCurrency"/></xsl:when>
					<xsl:otherwise>
						<mapper:logError>
							No currency specified within invoice.
						</mapper:logError>
					</xsl:otherwise>
				</xsl:choose>
			</mapper:setVar>
		
			<!-- Sequence number for the ST -->
			<xsl:variable name="STGenNumber">
				<xsl:value-of select="concat($batchGenNumber, str:pad(position(), 4, '0', 'true'))"/>
			</xsl:variable>
			
			<mapper:incVar name="messageCount"/>
			<mapper:setVar name="segmentCount">0</mapper:setVar>

			<mapper:logMessage>
				Invoice number: <xsl:value-of select="InvoiceNumber"/>
			</mapper:logMessage>
						
			<ST>
				<mapper:incVar name="segmentCount"/>
				<Field>810</Field>
				<Field><xsl:value-of select="$STGenNumber"/></Field>
			</ST>
			
			<xsl:if test="string-length(OrderDate/Customers) = 0">
				<mapper:logError>
					Customer order date is required.
				</mapper:logError>			
			</xsl:if>

			<xsl:if test="string-length(OrderNumber/Customers) = 0">
				<mapper:logError>
					Customer order number is required.
				</mapper:logError>			
			</xsl:if>

			<BIG>
				<mapper:incVar name="segmentCount"/>
				<Field minLen="8" maxLen="8" tag="Invoice-Date"> <!-- Invoice date -->
					<date:reformat curFormat="yyyy-MM-dd" newFormat="yyyyMMdd">
						<xsl:value-of select="InvoiceDate"/>
					</date:reformat>
				</Field>
				<Field minLen="1"><xsl:value-of select="InvoiceNumber"/></Field>
				<Field> <!-- Order date -->
					<date:reformat curFormat="yyyy-MM-dd" newFormat="yyyyMMdd">
						<xsl:value-of select="OrderDate/Customers"/>
					</date:reformat>
				</Field>
				<Field><xsl:value-of select="OrderNumber/Customers"/></Field>
				<Field/>
				<Field/>
				<Field><!-- Transaction Type Code -->
					<xsl:value-of select="'DI'"/><!-- DI = Debit Invoice -->
				</Field>
			</BIG>

			<CUR>
				<mapper:incVar name="segmentCount"/>
				<Field/>
				<Field minLen="1" tag="Invoice-Currency"><xsl:value-of select="@currency"/></Field>
			</CUR>

			<PER>
				<mapper:incVar name="segmentCount"/>
				<Field minLen="1"><xsl:value-of select="'BD'"/></Field>
				<Field minLen="1" tag="Buyer-Name-or-Department"><xsl:value-of select="Customer/FreeText[1]"/></Field>
			</PER>

			<N1>
					<mapper:incVar name="segmentCount"/>
					<Field><xsl:value-of select="'RE'"/></Field> <!-- RE = Remit to Name -->
					<Field><xsl:value-of select="Customer/Name"/></Field>

					<N3>
						<mapper:incVar name="segmentCount"/>
						<Field><xsl:value-of select="Customer/Address/Title"/></Field>
						<Field><xsl:value-of select="Customer/Address/Street"/></Field>
					</N3>

					<N4>
						<mapper:incVar name="segmentCount"/>
						<Field><xsl:value-of select="Customer/Address/City"/></Field>
						<Field><xsl:value-of select="Customer/Address/State"/></Field>
						<Field><xsl:value-of select="Customer/Address/PostCode"/></Field>
						<Field><xsl:value-of select="Customer/Address/Country"/></Field>
					</N4>
			</N1>

			<N1>
					<mapper:incVar name="segmentCount"/>
					<Field><xsl:value-of select="'SF'"/></Field> <!-- SF = Ship From -->
					<Field><xsl:value-of select="Supplier/Name"/></Field>

					<N3>
						<mapper:incVar name="segmentCount"/>
						<Field><xsl:value-of select="Supplier/Address/Title"/></Field>
						<Field><xsl:value-of select="Supplier/Address/Street"/></Field>
					</N3>

					<N4>
						<mapper:incVar name="segmentCount"/>
						<Field><xsl:value-of select="Supplier/Address/City"/></Field>
						<Field><xsl:value-of select="Supplier/Address/State"/></Field>
						<Field><xsl:value-of select="Supplier/Address/PostCode"/></Field>
						<Field><xsl:value-of select="Supplier/Address/Country"/></Field>
					</N4>
			</N1>

			<N1>
					<mapper:incVar name="segmentCount"/>
					<Field><xsl:value-of select="'ST'"/></Field> <!-- ST = Ship To -->
					<Field><xsl:value-of select="DeliverTo/Name"/></Field>
					<Field><xsl:value-of select="'9'"/></Field>
					<Field><xsl:value-of select="DeliverTo/EanCode"/></Field>

					<N3>
						<mapper:incVar name="segmentCount"/>
						<Field minLen="1" tag="Deliver-Title"><xsl:value-of select="DeliverTo/Address/Title"/></Field>
						<Field><xsl:value-of select="DeliverTo/Address/Street"/></Field>
					</N3>

					<N4>
						<mapper:incVar name="segmentCount"/>
						<Field><xsl:value-of select="DeliverTo/Address/City"/></Field>
						<Field><xsl:value-of select="DeliverTo/Address/State"/></Field>
						<Field><xsl:value-of select="DeliverTo/Address/PostCode"/></Field>
						<Field><xsl:value-of select="DeliverTo/Address/Country"/></Field>
					</N4>
			</N1>

			<DTM>
					<mapper:incVar name="segmentCount"/>
					<Field><xsl:value-of select="'011'"/></Field> <!-- Shipped Date -->
					<Field>
						<date:reformat curFormat="yyyy-MM-dd" newFormat="yyyyMMdd">
							<xsl:value-of select="DeliveryNoteDate"/>
						</date:reformat>
					</Field>
			</DTM>

			<xsl:apply-templates select="InvoiceLine"/>
		
			<TDS>
				<mapper:incVar name="segmentCount"/>				
				<Field><xsl:value-of select="InvoiceSummary/Total4 * 100"/></Field> <!-- including discount and charges (+ Tax), without settlement -->
				<Field/> <!-- Amount Subject to Cash Discount -->
				<Field/> <!-- Discounted (Net) Invoice Amount -->
				<Field/> <!-- Terms Discount Amount -->
			</TDS>
		
			<xsl:if test="InvoiceSummary/Discount &gt; 0">
				<SAC>
					<mapper:incVar name="segmentCount"/>
					<Field>A</Field> <!-- A = allowance -->
					<Field></Field> <!-- Service promo, allow, charge code -->
					<Field/>
					<Field/>
					<Field><xsl:value-of select="InvoiceSummary/Discount * 100"/></Field>
					<Field></Field> <!-- Allowance/Charge percent qualifier -->
					<Field></Field> <!-- Percent, format 9.99 or .9999 -->
					<Field></Field> <!-- rate -->
					<Field/>
					<Field/>
					<Field/>
					<Field>02</Field> <!-- method, 02 or 06 (decimal places) -->
					<Field/>
					<Field/>
					<Field>Quantity Discount</Field> <!-- Description -->
				</SAC>
			</xsl:if>
			
			<xsl:if test="InvoiceSummary/Surcharge &gt; 0">
				<SAC>
					<mapper:incVar name="segmentCount"/>
					<Field>C</Field> <!-- C = allowance -->
					<Field>D240</Field> <!-- Service promo, allow, charge code -->
					<Field/>
					<Field/>
					<Field><xsl:value-of select="InvoiceSummary/Surcharge * 100"/></Field>
					<Field></Field> <!-- Allowance/Charge percent qualifier -->
					<Field></Field> <!-- Percent, format 9.99 or .9999 -->
					<Field></Field> <!-- rate -->
					<Field/>
					<Field/>
					<Field/>
					<Field>02</Field> <!-- method, 02 or 06 (decimal places) -->
					<Field/>
					<Field/>
					<Field>Shipping</Field> <!-- Description -->
				</SAC>
			</xsl:if>

			<xsl:apply-templates select="VatSummary"/>

			<CTT>
				<mapper:incVar name="segmentCount"/>
				<Field><xsl:value-of select="count(InvoiceLine)"/></Field>
			</CTT>
		
			<SE>
				<mapper:incVar name="segmentCount"/>
				<Field><xsl:value-of select="mapper:getVar('segmentCount')"/></Field>			
				<Field><xsl:value-of select="$STGenNumber"/></Field>			
			</SE>
		</xsl:template>
		
		
		<xsl:template match="InvoiceLine">
			<IT1>
				<mapper:incVar name="segmentCount"/>				
				<Field><xsl:value-of select="Product/LineNumber"/></Field>
				<Field><xsl:value-of select="Quantity/Amount"/></Field> <!-- Quantity invoiced -->
				<Field>
					<!--
						CA = Case
						EA = Each
						RL = Roll
						SF = Square Foot
						SY = Square Yard
						LF = Linear Foot
						CT = Carton
						PL = Pallet
						TC = Truckload
						BG = Bags
						PA = Pails
						PC = Pieces
						SH = Sheets
						ST = Sets
						BX = Box					
					-->
					<xsl:choose>
						<xsl:when test="Quantity/MeasureIndicator = 'Each'">EA</xsl:when>
						<xsl:when test="Quantity/MeasureIndicator = 'Case'">CS</xsl:when>
						<xsl:otherwise>EA</xsl:otherwise>
					</xsl:choose>
				</Field>
				<Field><xsl:value-of select="Price/UnitPrice"/></Field>
				<Field><xsl:value-of select="'PE'"/></Field> <!-- PE = Price Per Each -->
				<Field><xsl:value-of select="'BP'"/></Field> <!-- Buyers part number -->
				<Field><xsl:value-of select="Product/CustomersCode"/></Field> <!-- Product code -->
				<Field><xsl:value-of select="'VP'"/></Field> <!-- Vendors Part Number -->
				<Field><xsl:value-of select="Product/SuppliersCode"/></Field> <!-- Product code -->
			</IT1>
			
			<PID>
				<mapper:incVar name="segmentCount"/>
				<Field>F</Field> <!-- Description type. F = Free Form -->
				<Field/>
				<Field/>
				<Field/>
				<Field tag="PID-Description" maxLen="80" minLen="1">
					<xsl:value-of select="Product/Name"/>
				</Field>
			</PID>

			<TXI>
				<mapper:incVar name="segmentCount"/>
				<Field><xsl:value-of select="'VA'"/></Field>
				<Field><xsl:value-of select="Vat/LineVat"/></Field>
				<Field><xsl:value-of select="Vat/Percentage"/></Field>
			</TXI>

			<xsl:if test="Price/LineDiscount &gt; 0">
				<SAC>
					<mapper:incVar name="segmentCount"/>
					<Field>A</Field> <!-- A = allowance -->
					<Field>ZZZZ</Field> <!-- Service promo, allow, charge code -->
					<Field/>
					<Field/>
					<Field><xsl:value-of select="Price/LineDiscount * 100"/></Field>
					<Field></Field> <!-- Allowance/Charge percent qualifier -->
					<Field></Field> <!-- Percent, format 9.99 or .9999 -->
					<Field></Field> <!-- rate -->
					<Field/>
					<Field/>
					<Field/>
					<Field>02</Field> <!-- method, 02 or 06 (decimal places) -->
					<Field/>
					<Field/>
					<Field>Quantity Discount</Field> <!-- Description -->
				</SAC>
			</xsl:if>
			
			<xsl:if test="Price/Charge &gt; 0">
				<SAC>
					<mapper:incVar name="segmentCount"/>
					<Field>C</Field> <!-- C = allowance -->
					<Field>ZZZZ</Field> <!-- Service promo, allow, charge code -->
					<Field/>
					<Field/>
					<Field><xsl:value-of select="Price/Charge * 100"/></Field>
					<Field></Field> <!-- Allowance/Charge percent qualifier -->
					<Field></Field> <!-- Percent, format 9.99 or .9999 -->
					<Field></Field> <!-- rate -->
					<Field/>
					<Field/>
					<Field/>
					<Field>02</Field> <!-- method, 02 or 06 (decimal places) -->
					<Field/>
					<Field/>
					<Field>Shipping</Field> <!-- Description -->
				</SAC>
			</xsl:if>
			
		</xsl:template>	

		<xsl:template match="VatSummary">

			<TXI>
				<mapper:incVar name="segmentCount"/>
				<Field><xsl:value-of select="'VA'"/></Field>
				<Field minLen="1"><xsl:value-of select="VatAmount"/></Field>
				<Field><xsl:value-of select="VatPercentage"/></Field>
			</TXI>

		</xsl:template>
		
</xsl:stylesheet>
