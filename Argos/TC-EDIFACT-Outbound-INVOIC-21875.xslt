<?xml version="1.0" encoding="utf-8"?>
<!--
	XSLT to transform a Generic XML INVOIC into a EANCOM 901 Invoice.
	
	Input: Generic XML Invoice.
	Output: EANCOM 901 Invoice.
	
	Author: Jennifer Ciambro
	Version: 1.0
	Creation Date: 25-July-2017
		
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:date="com.css.base.xml.xslt.ext.XsltDateExtension" xmlns:str="com.css.base.xml.xslt.ext.XsltStringExtension" xmlns:edifact="com.css.base.xml.xslt.ext.edi.XsltParsedEdifactEdiExtension" xmlns:mapper="com.api.tx.MapperEngine" extension-element-prefixes="date mapper str edifact">
    <xsl:output method="xml" />
    <xsl:param name="SenderEnvelopeQualifier" />
    <xsl:param name="TestMode" />
    <!-- true if to override the partner default -->
    <xsl:param name="CustomerCodeForSupplier" />
    <!-- Optional if not supplied in the generic XML -->
    <xsl:param name="Network" />
    <!-- AS2 or TGMS. If not specified then it defaults to TGMS -->
    <xsl:param name="Container" />
    <!-- If not in the Type/Customers or Type/Suppliers then you can use this. Set to CHEP or EURO -->
    <xsl:param name="BoxType" />
    <!-- If not in the SuppliedIn then you can use this. Set to TRAY or BOX -->
    <xsl:param name="NetworkPassword" />
    <xsl:param name="UseConsolidator" select="'true'" />
    <!-- Additional text to include within the batch reference stored in the property files.
			Useful if more than one account exists on the same supplier ANA. -->
    <xsl:param name="BatchRefText" />
    <xsl:template match="/">
        <xsl:apply-templates select="Batch" />
    </xsl:template>
    <xsl:template match="Batch">
		
		<xsl:variable name="receiverANA" select="/Batch/Invoice[1]/BatchReferences/ReceiverCode" />
        <!-- Some hubs specify different criterea in test and live modes -->
        <xsl:variable name="testMode" select="/Batch/Invoice[1]/BatchReferences/@test = 'true' or $TestMode = 'true'" />
        <xsl:variable name="vendorID">
            <xsl:choose>
                <xsl:when test="string-length($CustomerCodeForSupplier) &gt; 0">
                    <xsl:value-of select="$CustomerCodeForSupplier" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="/Batch/ASN[1]/Supplier/CustomersCode" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <Document type="EDIFACT" wrapped="false">
            <xsl:attribute name="syntax">
                <xsl:value-of select="'UNOA'" />
            </xsl:attribute>
            <xsl:attribute name="version">
                <xsl:value-of select="'3'" />
            </xsl:attribute>
            <mapper:setVar name="messageCount">0</mapper:setVar> <!-- Segment counter do not remove -->
            <UNB>
                <Field> <!-- UNB 1-->
                    <Field>UNOA</Field> <!-- UNB 1.1-->
                    <Field>3</Field> <!-- UNB 1.2-->
                </Field>
                <Field> <!-- UNB 2-->
                    <Field> <!-- UNB 2.1-->
                        <xsl:value-of select="/Batch/Invoice[1]/BatchReferences/SenderCode" />
                    </Field>
                    <Field> <!-- UNB 2.2-->
                        <xsl:value-of select="/Batch/Invoice[1]/BatchReferences/SenderCodeQualifier" />
                    </Field>
                </Field>
                <Field> <!-- UNB 3 -->
                    <Field> <!-- UNB 3.1-->
                        <xsl:value-of select="/Batch/Invoice[1]/BatchReferences/ReceiverCode" />
                    </Field>
                    <Field> <!-- UNB 3.2-->
                        <xsl:value-of select="/Batch/Invoice[1]/BatchReferences/ReceiverCodeQualifier" />
                    </Field>
                </Field>
                <Field> <!-- UNB 4-->
                    <Field> <!-- UNB 4.1 -->
                        <xsl:value-of select="date:insert('yyMMdd')" />
                    </Field>
                    <Field> <!-- UNB 4.2 -->
                        <xsl:value-of select="date:insert('hhmm')" />
                    </Field>
                </Field> 
                <Field> <!-- UNB 5 -->
                    <xsl:value-of select="/Batch/Invoice[1]/BatchReferences/BatchRef" />
                </Field>
                <Field> <!-- UNB 6 -->
                    <xsl:value-of select="$NetworkPassword" />
                </Field>
                <Field>INVOIC</Field> <!-- UNB 7 -->
                <Field /> <!-- UNB 8 -->
                <Field /> <!-- UNB 9 -->
                <Field /> <!-- UNB 10 -->
                <Field> <!-- UNB 11 -->
                        <xsl:value-of select="Batch/Invoice[1]/BatchReferences/test" />
                </Field>
                <xsl:apply-templates select="Invoice">
                    <xsl:with-param name="batchRef"/>
                </xsl:apply-templates>
                <UNZ> 
                    <Field> <!-- UNZ 1 -->
                        <mapper:getVar name="messageCount" />
                    </Field>
                    <Field> <!-- UNZ 2 -->
                        <xsl:value-of select="/Batch/Invoice[1]/BatchReferences/BatchRef" />
                    </Field>
                </UNZ>
            </UNB>
        </Document>
    </xsl:template>
    <xsl:template match="Invoice">
        <xsl:param name="batchRef" />
        <xsl:variable name="GenNumber">
            <xsl:value-of select="position()" />
        </xsl:variable>
        <xsl:variable name="MsgRefNum">
            <xsl:value-of select="UNH/MsgRefNum" />
        </xsl:variable>
        <mapper:incVar name="messageCount" />
        <mapper:setVar name="segmentCount">0</mapper:setVar>
        <UNH>
            <mapper:incVar name="segmentCount" />
             <Field> <!-- UNH 1 -->
                <xsl:value-of select="$MsgRefNum" />
            </Field>
            <Field> <!-- UNH 2 -->
                <Field> <!-- UNH 2.1 -->
					<xsl:value-of select="UNH/MsgType" />
				</Field>
                <Field> <!-- UNH 2.2 -->
					<xsl:value-of select="UNH/MsgVersion" />
				</Field>
                <Field> <!-- UNH 2.3 -->
					<xsl:value-of select="UNH/MsgReleaseNum" />
				</Field>
                <Field> <!-- UNH 2.4 -->
					<xsl:value-of select="UNH/ControlAgency" />
				</Field>
				<Field>EAN008</Field>
				<Field/> <!-- UNH 2.6 -->
				<Field/> <!-- UNH 2.7 -->
            </Field>
            <BGM>
                <mapper:incVar name="segmentCount" />
                <Field> <!-- BGM 1 -->
                    <Field> <!-- BGM 1.1 -->
						<xsl:value-of select="BGM/DocMsgCode" />
					</Field>
                    <Field/> <!-- BGM 1.2 -->
                    <Field/> <!-- BGM 1.3-->
					<Field/> <!-- BGM 1.4 -->
				</Field>
                <Field> <!-- BGM 2 -->
                    <xsl:value-of select="BGM/DocNum" />
                </Field>
                <Field> <!-- BGM 3 -->
					<xsl:value-of select="BGM/InvoiceDate" />
				</Field>
				<Field> <!-- BGM 4 -->
				</Field>
            </BGM>
			<xsl:if test="string-length(NAD.SU/Code) &gt;0">
			<NAD>
				<mapper:incVar name="segmentCount" />
                <Field>SU</Field>
				<Field>
					<xsl:value-of select="NAD.SU/Code" />
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.SU/Name" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.SU/Address1" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.SU/City" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.SU/State" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.SU/Zip" />
					</Field>
				</Field>
			</NAD>
			</xsl:if>
			<xsl:if test="string-length(NAD.BY/Name) &gt;0">
			<NAD>
				<mapper:incVar name="segmentCount" />
                <Field>BY</Field>
				<Field></Field>
				<Field></Field>
				<Field>
					<xsl:value-of select="NAD.BY/Name" />
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.BY/Address1" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.BY/Address2" />
					</Field>
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.BY/City" />
					</Field>
				</Field>
				<Field></Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.BY/Zip" />
					</Field>
				</Field>
			</NAD>
			</xsl:if>
			<xsl:if test="string-length(NAD.DP/Code) &gt;0">
			<NAD>
				<mapper:incVar name="segmentCount" />
                <Field>DP</Field>
				<Field>
					<xsl:value-of select="NAD.DP/Code" />
				</Field>
			</NAD>
			</xsl:if>
            <DTM>
                <mapper:incVar name="segmentCount" />
               <Field>131</Field>
               <Field>
                   <xsl:value-of select="DTM/TaxPointDate" />
               </Field>
            </DTM>
			<CUX>
				<mapper:incVar name="segmentCount" />
				<Field>
					<xsl:value-of select="CUX/Currency" />
				</Field>
			</CUX>
			<xsl:for-each select="Item">
					<LIN>
						<mapper:incVar name="segmentCount" />
						<Field>
							<xsl:value-of select="LIN/LineNum" />
						</Field>
						<Field></Field>
						<Field>
							<Field>
							<xsl:value-of select="LIN/ItemHubNumber" />
							</Field>
							<xsl:if test="string-length(LIN/ItemHubNumber) &gt; 0">
							<Field>IN</Field>
							</xsl:if>
						</Field>
						<Field>
							<Field>
							<xsl:value-of select="LIN/ItemVendorIDNumber" />
							</Field>
							<xsl:if test="string-length(LIN/ItemVendorIDNumber) &gt; 0">
							<Field>VN</Field>
							</xsl:if>
						</Field>
						<Field>
							<Field>47</Field>
							<Field>
								<xsl:value-of select="LIN/Quantity" />
							</Field>
						</Field>
						<Field>
							<Field>
								<xsl:value-of select="LIN/ItemCost" />
							</Field>
							<Field>NT</Field>
						</Field>
						<Field></Field>
						<Field>
							<xsl:value-of select="LIN/ItemAmount" />
						</Field>
						<RFF>
						<mapper:incVar name="segmentCount" />
							<Field>ON</Field>
							<Field>
								<xsl:value-of select="LIN/RFF/ItemOrderNumber" />
							</Field>
						</RFF>
						<RFF>
						<mapper:incVar name="segmentCount" />
							<Field>AAU</Field>
							<Field>
								<xsl:value-of select="LIN/RFF/AdviceNoteNumber" />
							</Field>
						</RFF>
						<IMD>
							<Field/>
							<Field/>
							<Field/>
							<Field>
								<xsl:value-of select="LIN/IMD/Desc" />
							</Field>
						</IMD>
						<xsl:if test="string-length(TRI/VATTaxRate) &gt;0">
						<TRI>
							<Field>VAT</Field>
							<Field>
								<xsl:value-of select="LIN/TRI/VATTaxRate" />
							</Field>
							<Field>
								<xsl:value-of select="LIN/TRI/VATTaxPercent" />
							</Field>
							<Field>
								<xsl:value-of select="LIN/TRI/VATTaxAmount" />
							</Field>
						</TRI>
						</xsl:if>
					</LIN>
                </xsl:for-each>
			<UNS>
				<mapper:incVar name="segmentCount" />
				<Field>S</Field>
			</UNS>
			<TMA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<xsl:value-of select="TMA/Total" />
				</Field>
				<Field>
					<xsl:value-of select="TMA/LineItemTotal" />
				</Field>
				<Field>
					<xsl:value-of select="TMA/AmtSubjectToDiscount" />
				</Field>
				<Field>
					<xsl:value-of select="TMA/AmtSubjectToTax" />
				</Field>
				<Field></Field>
				<Field>
					<xsl:value-of select="TMA/TotalTaxAmount" />
				</Field>
			</TMA>
			<xsl:if test="string-length(TRI/VATTaxPercent) &gt; 0">
			<TXS>
				<mapper:incVar name="segmentCount" />
				<Field>VAT</Field>
				<Field>S</Field>
				<Field>
					<xsl:value-of select="TXS/TotalVATPercent" />
				</Field>
				<Field>
					<xsl:value-of select="TXS/VATIdNum" />
				</Field>
				<Field>
					<xsl:value-of select="TXS/VATTaxCategory" />
				</Field>
			</TXS>
			</xsl:if>
            <UNT>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <mapper:getVar name="segmentCount" />
                </Field>
                <!-- number of segments in message -->
                <Field>
                    <xsl:value-of select="$MsgRefNum" />
                </Field>
                <!-- UNH reference number -->
            </UNT>
        </UNH>
    </xsl:template>
 </xsl:stylesheet>