<?xml version="1.0" encoding="utf-8"?>
<!--
	
	
	Input: TC XML Invoice.
	Output: MECCA BRANDS EDIFACT CONTRL.
	
	Author: Jennifer Ciambro		
	Version: 1.0
	Creation Date: December 5, 2017
		
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
				<AckRequested><xsl:value-of select="edi:getElement($envelope, 9)"/></AckRequested>
			</BatchReferences>
			<UNH>
				<MsgRefNum>
					<xsl:value-of select="edi:getElement(UNH, 1)"/>
				</MsgRefNum>
				<MsgType>
					<xsl:value-of select="edi:getSubElement(UNH, 2, 1)"/>
				</MsgType>
				<MsgVersion>
					<xsl:value-of select="edi:getSubElement(UNH, 2, 2)"/>
				</MsgVersion>
				<MsgReleaseNum>
					<xsl:value-of select="edi:getSubElement(UNH, 2, 3)"/>
				</MsgReleaseNum>
				<ControlAgency>
					<xsl:value-of select="edi:getSubElement(UNH, 2, 4)"/>
				</ControlAgency>
			</UNH>
			<UCI>
				<AckCntrlNum>
					<xsl:value-of select="edi:getElement(UCI, 1)"/>
				</AckCntrlNum>
				<SenderID>
					<xsl:value-of select="edi:getSubElement(UCI, 2, 1)"/>
				</SenderID>
				<SenderIDQual>
					<xsl:value-of select="edi:getSubElement(UCI, 2, 2)"/>
				</SenderIDQual>
				<ReceiverID>
					<xsl:value-of select="edi:getSubElement(UCI, 3, 1)"/>
				</ReceiverID>
				<ReceiverIDQual>
					<xsl:value-of select="edi:getSubElement(UCI, 3, 2)"/>
				</ReceiverIDQual>
				<ActionCoded>
					<xsl:value-of select="edi:getElement(UCI, 4)"/>
				</ActionCoded>
			</UCI>
			<UNT>
				<NumSegments>
					<xsl:value-of select="edi:getElement(UNT, 1)"/>
				</NumSegments>
				<MessageReference>
					<xsl:value-of select="edi:getElement(UNT, 2)"/>
				</MessageReference>
			</UNT>
	</xsl:template>
</xsl:stylesheet>