<?xml version="1.0"?>
<!--
	XSLT to transform a Generic XML ASN into an X12 856 message for Walgreens.
	
	Input: Generic XML ASN.
	Output: X12 856.
	
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

	<xsl:param name="SenderEnvelopeQualifier"/>

  <xsl:template match="/">
		<xsl:apply-templates select="Batch"/>
  </xsl:template>

  <xsl:template match="Batch">
		<mapper:logMessage>
			Transforming to Walgreens Ansi X12 EDI 856
		</mapper:logMessage>
		
		<xsl:variable name="testMode" select="/Batch/ASN[1]/BatchReferences/@test"/>

		<xsl:variable name="GenNumber">
			<mapper:genNum>
				<xsl:value-of select="concat(/Batch/ASN[1]/BatchReferences/SenderCode, '.', /Batch/ASN[1]/BatchReferences/ReceiverCode, '.', 'DESPATCH', '.', $testMode)"/>
			</mapper:genNum>
		</xsl:variable>

		<xsl:variable name="GenNumber">
			<mapper:genNum>
				<xsl:value-of select="concat(/Batch/ASN[1]/BatchReferences/SenderCode, '.',  '.', '856', '.', $testMode)"/>
			</mapper:genNum>
		</xsl:variable>

		<xsl:variable name="BatchGenNumber">
			<xsl:value-of select="str:pad($GenNumber, 5, '0', 'true')"/>
		</xsl:variable>

		<!-- This is for filename generation -->
		<mapper:setVar name="BatchSequence"><xsl:value-of select="$BatchGenNumber"/></mapper:setVar>

		<Document type="X12" wrapped="true" fieldSep="*" recSep="&#x0A;">
			<!-- ISA. This is fixed position, hence the pad jazz -->
			<ISA>
				<Field padDir="right" padSize="2" padChar=" ">00</Field> <!-- Authorisation information qualifier -->
				<Field padDir="right" padSize="10" padChar=" "></Field> <!-- Authorisation information -->
				<Field padDir="right" padSize="2" padChar=" ">00</Field> <!-- Security information qualifier -->
				<Field padDir="right" padSize="10" padChar=" "></Field> <!-- Security information -->
				<Field padDir="right" padSize="2" padChar=" "><xsl:value-of select="$SenderEnvelopeQualifier"/></Field> <!-- Sender qualifier -->
				<Field padDir="right" padSize="15" padChar=" "><xsl:value-of select="ASN[1]/BatchReferences/SenderCode"/></Field>
				<Field padDir="right" padSize="2" padChar=" "> <!-- Receiver qualifier -->
					<xsl:choose>
						<xsl:when test="$testMode = 'true'">01</xsl:when>
						<xsl:otherwise>01</xsl:otherwise>
					</xsl:choose>
				</Field>
				<Field padDir="right" padSize="15" padChar=" "><xsl:value-of select="ASN[1]/BatchReferences/ReceiverCode"/></Field>
				<Field padDir="right" padSize="6" padChar=" "><xsl:value-of select="date:insert('yyMMdd')"/></Field>
				<Field padDir="right" padSize="4" padChar=" "><xsl:value-of select="date:insert('HHmm')"/></Field>
				<Field padDir="right" padSize="1" padChar=" ">U</Field> <!-- interchange control standards ID -->
				<Field padDir="right" padSize="5" padChar=" ">00401</Field> <!-- interchange control version number -->
				<Field padDir="left" padSize="9" padChar="0"><xsl:value-of select="$BatchGenNumber"/></Field> <!-- batch number -->
				<Field padDir="right" padSize="1" padChar=" ">0</Field> <!-- Ack (997) requested, 0 or 1 -->
				<Field padDir="right" padSize="1" padChar=" "> <!-- Test indicator T = test, P = production -->
					<xsl:choose>
						<xsl:when test="$testMode = 'true'">P</xsl:when> <!-- They are P only -->
						<xsl:otherwise>P</xsl:otherwise>
					</xsl:choose>
				</Field>
				<Field padDir="right" padSize="1" padChar=" ">}</Field> <!-- Sub element sep -->
			</ISA>
		
			<!-- GS -->
			<GS>
				<Field>SH</Field> <!-- Functional ID code. SH =  -->
				<Field><xsl:value-of select="ASN[1]/BatchReferences/SenderCode"/></Field>
				<Field><xsl:value-of select="ASN[1]/BatchReferences/ReceiverCode"/></Field>
				<Field><xsl:value-of select="date:insert('yyyyMMdd')"/></Field>
				<Field><xsl:value-of select="date:insert('HHmm')"/></Field>
				<Field><xsl:value-of select="$BatchGenNumber"/></Field>
				<Field>X</Field> <!-- Responsibility Agency code -->
				<Field>004010</Field> <!-- Version / Rel. Ind. ID Code -->
			</GS>
				
			<mapper:setVar name="messageCount">0</mapper:setVar>				
			<xsl:apply-templates select="ASN">
				<xsl:with-param name="batchGenNumber" select="$BatchGenNumber"/>
			</xsl:apply-templates>		
		
			<!-- GE -->
			<GE>
				<Field><xsl:value-of select="count(ASN)"/></Field> <!-- Number of Messages -->
				<Field><xsl:value-of select="$BatchGenNumber"/></Field> <!-- ISA batch number -->
			</GE>
			
			<!-- IEA -->
			<IEA>
				<Field>1</Field> <!-- Number of Groups -->
				<Field padDir="left" padSize="9" padChar="0"><xsl:value-of select="$BatchGenNumber"/></Field> <!-- ISA batch number -->
			</IEA>		
		</Document>

  </xsl:template>


	<xsl:template match="ASN">
		<xsl:param name="batchGenNumber"/>

		<!-- Sequence number for the ST -->
		<xsl:variable name="STGenNumber">
			<xsl:value-of select="concat($batchGenNumber, str:pad(position(), 4, '0', 'true'))"/>
		</xsl:variable>

		<mapper:incVar name="messageCount"/>
		<mapper:setVar name="segmentCount">0</mapper:setVar>

		<mapper:logMessage>
			ASN number: <xsl:value-of select="DocumentNumber"/>
		</mapper:logMessage>
					
		<ST>
			<mapper:incVar name="segmentCount"/>
			<Field>856</Field>
			<Field><xsl:value-of select="$STGenNumber"/></Field>
		</ST>

		<BSN>
			<mapper:incVar name="segmentCount"/>
			<!-- purpose code. 00 = original, 01 = cancellation, 04 = change, 05 = replace -->
			<Field>00</Field>
			<!-- Shipment identification number -->
			<Field><xsl:value-of select="DocumentNumber"/></Field>
			<!-- date -->
			<Field>
				<date:reformat curFormat="yyyy-MM-dd" newFormat="yyyyMMdd">
					<xsl:value-of select="DocumentDate"/>
				</date:reformat>
			</Field> 
			<!-- time -->
			<Field>
				<date:reformat curFormat="HH:mm:ss" newFormat="HHmm">
					<xsl:value-of select="'00:00:00'"/>
				</date:reformat>
			</Field>
			<!-- Hierarchichal Structure Code -->
			<Field>0001</Field>
			<!-- Transaction Type Code -->
			<Field>AS</Field><!-- AS = Shipment Advice -->
		</BSN>

		<!-- Shipment info -->
		<HL>
			<mapper:incVar name="segmentCount"/>
			<Field>1</Field> <!-- hierarchy ID -->
			<Field/>
			<Field>S</Field> <!-- S = shipment -->
			<Field>1</Field> <!-- Hierarchical Child Code -->
	
			<TD1>
				<mapper:incVar name="segmentCount"/>
				<!-- Packaging code:
					Code (Part 1)	Description
					CTN	Carton
					PLT	Pallet
						
					Code (Part 2)	Description
					01	Aluminum
					25	Corrugated or Solid
					31	Fiber
					58	Metal
					71	Not Otherwise Specified
					72	Paper
					75	Plastic
					91	Stainless Steel
					94	Wood				
				 -->
				<Field>PLT</Field> <!-- eg: PLT means pallet -->
				<!-- Lading quantity (i think this is number of pallets?) -->
				<Field><xsl:value-of select="count(Package[@type = 'outer'])"/></Field>
			</TD1>
			
			<TD5>
				<mapper:incVar name="segmentCount"/>
				<Field></Field> <!-- Not used -->
				<Field>2</Field> <!-- 2 = SCAC (standard carrier alpha code) -->
				<Field/><!-- ID code for above qualifier -->
				<!--
					Transport method type code:
						Code	Description
						A	Air
						C	Consolidation
						L	Contract Carrier
						LT	Less Then Trailer Load (LTL)
						M	Motor Common Carrier
						R	Rail
						SR	Supply Truck
						VE	Vessel, Ocean					
				-->
				<Field/>
				<Field/>
				<!-- Shipment/Order Status Code -->
				<Field><xsl:value-of select="'CC'"/></Field>
			</TD5>
			
			<TD3>
				<mapper:incVar name="segmentCount"/>
				<!--
					Equipment description code:
						CN = Container
						TL = Trailer
				-->
				<Field>TL</Field>
				<!-- Equipment initial -->
				<Field></Field>
				<!-- Equipment number -->
				<Field><xsl:value-of select="Consignor/TransportID"/></Field>
			</TD3>
					
			<REF>
				<!-- Reference qualifier -->
				<Field>CN</Field> <!-- CN = Carriers Ref. -->
				<!-- Reference number -->
				<Field><xsl:value-of select="DocumentNumber"/></Field>
			</REF>	

			<REF>
				<!-- Reference qualifier -->
				<Field>VR</Field> <!-- VR = Vendor ID -->
				<!-- Reference number -->
				<Field><xsl:value-of select="Supplier/CustomersCode"/></Field>
			</REF>

			<REF>
				<!-- Reference qualifier -->
				<Field>BM</Field> <!-- Bill of Lading Number -->
				<!-- Reference number -->
				<Field><xsl:value-of select="ShipmentReference"/></Field>
			</REF>

                        <DTM>
                                <mapper:incVar name="segmentCount"/>
                                <Field>011</Field> <!-- date qualifier. 011 = shipped -->
                                <!-- date -->
                                <Field>
                                        <date:reformat curFormat="yyyy-MM-dd" newFormat="yyyyMMdd">
                                                        <xsl:value-of select="ShippingDate"/>
                                        </date:reformat>
                                </Field>
                                <!-- time -->
                                <Field>
                                        <date:reformat curFormat="HH:mm:ss" newFormat="HHmm">
                                                <xsl:choose>
                                                        <xsl:when test="string-length(DeliveryNoteTime) &gt; 0"><xsl:value-of select="DeliveryNoteTime"/></xsl:when>
                                                        <xsl:when test="string-length(DeliveryTime) &gt; 0"><xsl:value-of select="DeliveryTime"/></xsl:when>
                                                        <xsl:otherwise><xsl:value-of select="Package[1]/Product[1]/DeliveryNoteTime"/></xsl:otherwise>
                                                </xsl:choose>
                                        </date:reformat>
                                </Field>
                        </DTM>

                        <DTM>
                                <mapper:incVar name="segmentCount"/>
                                <Field>017</Field> <!-- date qualifier. 017 = Estimated Delivery-->
                                <!-- date -->
                                <Field>
                                        <date:reformat curFormat="yyyy-MM-dd" newFormat="yyyyMMdd">
                                                        <xsl:value-of select="ExpectedDeliveryDate"/>
                                        </date:reformat>
                                </Field>
                                <!-- time -->
                                <Field>
                                        <date:reformat curFormat="HH:mm:ss" newFormat="HHmm">
                                                <xsl:choose>
                                                        <xsl:when test="string-length(DeliveryNoteTime) &gt; 0"><xsl:value-of select="DeliveryNoteTime"/></xsl:when>
                                                        <xsl:when test="string-length(DeliveryTime) &gt; 0"><xsl:value-of select="DeliveryTime"/></xsl:when>
                                                        <xsl:otherwise><xsl:value-of select="Package[1]/Product[1]/DeliveryNoteTime"/></xsl:otherwise>
                                                </xsl:choose>
                                        </date:reformat>
                                </Field>
                        </DTM>

		<N1>
			<mapper:incVar name="segmentCount"/>
			<Field>ST</Field> <!-- ST = ship to -->
			<Field/>
			<Field>9</Field>
			<Field><xsl:value-of select="DeliverTo/CustomersCode"/></Field>

		</N1>

		<N1>
			<mapper:incVar name="segmentCount"/>
			<Field>SF</Field> <!-- SF = ship from -->
			<Field/>
			<Field>1</Field>
			<Field><xsl:value-of select="Consignor/EanCode"/></Field>

			<N4>
				<mapper:incVar name="segmentCount"/>
				<Field/>
				<Field/>
				<Field><xsl:value-of select="Consignor/Address/PostCode"/></Field>
			</N4>
		</N1>

		<HL>
			<mapper:incVar name="segmentCount"/>
			<Field><xsl:value-of select="position() + 1"/></Field> <!-- this Hlevel (starting at 2) -->
			<Field>1</Field> <!-- parent Hlevel -->
			<Field>O</Field> <!-- O = order -->
			<Field>1</Field> <!-- Hierarchical Child Code -->
			
			<PRF>
				<mapper:incVar name="segmentCount"/>
				<Field><xsl:value-of select="OrderNumber/Customers"/></Field>
				<Field/>
				<Field/>
				<Field>
					<date:reformat curFormat="yyyy-MM-dd" newFormat="yyyyMMdd">
						<xsl:value-of select="OrderDate/Customers"/>
					</date:reformat>
				</Field>
			</PRF>

		<mapper:setVar name="totalQuantity">0</mapper:setVar>
		
		<xsl:for-each select="Package">		
			<HL>
				<mapper:incVar name="segmentCount"/>
				<Field><xsl:value-of select="position() + 1"/></Field> <!-- this Hlevel (starting at 2) -->
				<Field>2</Field> <!-- parent Hlevel -->
				<Field>O</Field> <!-- O = order -->

				<MAN>
					<mapper:incVar name="segmentCount"/>
					<Field>GM</Field> <!-- GM = SSCC-18 -->
					<Field><xsl:value-of select="Markings/Barcode"/></Field>
				</MAN>
				
				<xsl:for-each select="Products">		

					<HL>
						<mapper:incVar name="segmentCount"/>
						<Field><xsl:value-of select="position() + 1"/></Field> <!-- this Hlevel (starting at 2) -->
						<Field></Field> <!-- parent Hlevel -->
						<Field>O</Field> <!-- O = order -->

						<LIN>
							<mapper:incVar name="segmentCount"/>
							<Field/>
							<Field>UP</Field> <!-- buyers part number -->
							<Field><xsl:value-of select="Product/EanCode"/></Field>
							<Field><xsl:value-of select="OrderNumber/Customers"/></Field>
						</LIN>
						
						<!-- Add this up for the general summary for the CTT at the end -->
						<mapper:addToVar name="totalQuantity"><xsl:value-of select="Quantity/Amount"/></mapper:addToVar>
						
						<SN1>
							<mapper:incVar name="segmentCount"/>
							<Field/>
							<!-- Number of units shipped -->
							<Field><xsl:value-of select="round(Quantity/Amount)"/></Field>
							<!-- UOM as sent in the 830 forecast order -->
							<Field>EA</Field>
							<!-- Number of units shipped to date -->
							<Field><xsl:value-of select="round(Quantity/Amount)"/></Field>
							<!-- Number of units ordered -->
							<Field><xsl:value-of select="round(Quantity/Amount)"/></Field>
							<!-- UOM -->
							<Field>EA</Field>
							<Field/>
							<!-- Line Item Status Code -->
							<Field>AC</Field>
						</SN1>

						<PO4>
							<mapper:incVar name="segmentCount"/>
							<Field><xsl:value-of select="Quantity/AmountPerUnit"/></Field>
							<Field></Field>
							<Field><xsl:value-of select="'CA'"/></Field>
						</PO4>

						<PID>
							<mapper:incVar name="segmentCount"/>
							<Field><xsl:value-of select="'F'"/></Field>
							<Field><xsl:value-of select="Name"/></Field>
						</PID>

						<DTM>
							<mapper:incVar name="segmentCount"/>
							<Field><xsl:value-of select="'036'"/></Field> <!-- 036 = Expiration -->
							<Field>
								<date:reformat curFormat="yyyy-MM-dd" newFormat="yyyyMMdd">
									<xsl:value-of select="ExpiryDate"/> <!-- Date -->
								</date:reformat>
							</Field>
						</DTM>
					</HL>
				</xsl:for-each> <!-- each product -->
			</HL>
		
		</xsl:for-each>
			</HL>
		</HL>

		<CTT>
			<mapper:incVar name="segmentCount"/>
			<Field><xsl:value-of select="count(Package)"/></Field>
			<Field><xsl:value-of select="round(mapper:getVar('totalQuantity'))"/></Field>
		</CTT>
		
		<SE>
			<mapper:incVar name="segmentCount"/>
			<Field><xsl:value-of select="mapper:getVar('segmentCount')"/></Field>			
			<Field><xsl:value-of select="$STGenNumber"/></Field>			
		</SE>

  </xsl:template>


</xsl:stylesheet>
