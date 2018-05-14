<?xml version="1.0" encoding="utf-8"?>
<!--
	XSLT to transform a Generic XML INVRPT into a EANCOM D97A INVRPT.
	
	Input: Generic XML INVRPT.
	Output: EANCOM D97A INVRPT.
	
	Author: Bill Freed
	Version: 1.0
	Creation Date: 12/14/2016
		
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
		
		<xsl:variable name="receiverANA" select="/Batch/InventoryReport[1]/BatchReferences/ReceiverCode" />
        <!-- Some hubs specify different criterea in test and live modes -->
        <xsl:variable name="testMode" select="/Batch/InventoryReport[1]/BatchReferences/@test = 'true' or $TestMode = 'true'" />
        <xsl:variable name="vendorID">
            <xsl:choose>
                <xsl:when test="string-length($CustomerCodeForSupplier) &gt; 0">
                    <xsl:value-of select="$CustomerCodeForSupplier" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="/Batch/InventoryReport[1]/Supplier/CustomersCode" />
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
                    <Field>2</Field> <!-- UNB 1.2-->
                </Field>
                <Field> <!-- UNB 2-->
                    <Field> <!-- UNB 2.1-->
                        <xsl:value-of select="/Batch/InventoryReport[1]/BatchReferences/SenderCode" />
                    </Field>
                    <Field>
						<xsl:value-of select="/Batch/InventoryReport[1]/BatchReferences/SenderCodeQualifier" />
                    </Field>
                </Field>
                <Field> <!-- UNB 3 -->
                    <Field> <!-- UNB 3.1-->
                        <xsl:value-of select="/Batch/InventoryReport[1]/BatchReferences/ReceiverCode" />
                    </Field>
                    <Field> <!-- UNB 3.2-->
                        <xsl:value-of select="/Batch/InventoryReport[1]/BatchReferences/ReceiverCodeQualifier" />
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
                    <xsl:value-of select="/Batch/InventoryReport[1]/BatchReferences/BatchRef" />
                </Field>
                <Field> <!-- UNB 6 -->
                    <xsl:value-of select="$NetworkPassword" />
                </Field>
                <Field>INVRPT</Field> <!-- UNB 7 -->
                <Field /> <!-- UNB 8 -->
                <Field /> <!-- UNB 9 -->
                <Field /> <!-- UNB 10 -->
                <Field> <!-- UNB 11 -->
                        <xsl:value-of select="Batch/InventoryReport[1]/BatchReferences/test" />
                </Field>
                <xsl:apply-templates select="InventoryReport">
                    <xsl:with-param name="batchRef"/>
                </xsl:apply-templates>
                <UNZ> 
                    <Field> <!-- UNZ 1 -->
                        <mapper:getVar name="messageCount" />
                    </Field>
                    <Field> <!-- UNZ 2 -->
                        <xsl:value-of select="/Batch/InventoryReport[1]/BatchReferences/BatchRef" />
                    </Field>
                </UNZ>
            </UNB>
        </Document>
    </xsl:template>
    <xsl:template match="InventoryReport">
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
                <Field>97A</Field>
                <Field> <!-- UNH 2.4 -->
					<xsl:value-of select="UNH/ControlAgency" />
				</Field>
				<Field> <!-- UNH 2.5 -->
					<xsl:value-of select="UNH/AssociationCode" />
				</Field>
				<Field/> <!-- UNH 2.6 -->
				<Field/> <!-- UNH 2.7 -->
            </Field>
            <BGM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>
						<xsl:value-of select="BGM/TransactionNoteType" />
					</Field>
                </Field>
                <Field>
                    <xsl:value-of select="BGM/DocDate" />
                </Field>
                <Field>9</Field>
			</BGM>
            <DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>137</Field>
                    <Field>
                        <xsl:value-of select="concat(DTM/DocDate, DTM/DocumentTime)" />
                    </Field>
                    <Field>203</Field>
                </Field>
            </DTM>
            <NAD> <!-- NAD.MI -->
                <mapper:incVar name="segmentCount" />
                <Field>MI</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="Issuer/Code" />
                    </Field>
                    <Field/>
                    <Field>
						<xsl:value-of select="Issuer/CodeType" />
                    </Field>
				</Field>
			</NAD>
			<NAD> <!-- NAD.SU -->
                <mapper:incVar name="segmentCount" />
                <Field>SU</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="Supplier/Code" />
                    </Field>
                    <Field/>
                    <Field>
						<xsl:value-of select="Supplier/CodeType" />
                    </Field>
				</Field>
			</NAD>
            <xsl:for-each select="Items">
				<LIN>
					<mapper:incVar name="segmentCount" />
					<Field/>
					<Field/>
					<Field>
						<Field>
							<xsl:value-of select="LIN/BuyersItemNum" />
						</Field>
						<Field>IN</Field>
					</Field>	
					<xsl:if test="string-length(LIN/PIA/VendorPartNum) &gt; 0">
					<PIA>
						<mapper:incVar name="segmentCount" />
						<Field>1</Field>
						<Field>
							<Field>
								<xsl:value-of select="LIN/PIA/VendorPartNum" />
							</Field>
							<Field>VP</Field>							
						</Field>				
					</PIA>
					</xsl:if>
					<xsl:if test="string-length(LIN/DTM/OldestBackorderDate) &gt; 0">					
					<DTM>
						<mapper:incVar name="segmentCount" />
						<Field>
							<Field>4</Field>
							<Field>
								<xsl:value-of select="LIN/DTM/OldestBackorderDate" />
							</Field>
							<Field>102</Field>
						</Field>
					</DTM>
					</xsl:if>
					<xsl:if test="string-length(LIN/DTM/PromisedForDate) &gt; 0">					
					<DTM>
						<mapper:incVar name="segmentCount" />
						<Field>
							<Field>79</Field>
							<Field>
								<xsl:value-of select="LIN/DTM/PromisedForDate" />
							</Field>
							<Field>102</Field>
						</Field>
					</DTM>
					</xsl:if>
					<INV>
						<mapper:incVar name="segmentCount" />
						<Field/>
						<Field>
							<xsl:value-of select="LIN/INV/InventoryAffectedCode" />
						</Field>
						<QTY>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>1</Field>
								<Field>
									<xsl:value-of select="LIN/INV/QTY/BackorderQty" />
								</Field>
							</Field>
						</QTY>
					</INV>
				</LIN>
            </xsl:for-each>
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