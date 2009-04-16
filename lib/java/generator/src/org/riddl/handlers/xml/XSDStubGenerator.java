package org.riddl.handlers.xml;


import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.xml.namespace.QName;
import javax.xml.stream.FactoryConfigurationError;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.riddl.generator.MessagePartContentStubGenerator;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;

import com.sun.codemodel.JType;
import com.sun.tools.xjc.ErrorReceiver;
import com.sun.tools.xjc.Language;
import com.sun.tools.xjc.ModelLoader;
import com.sun.tools.xjc.Options;
import com.sun.tools.xjc.model.Model;
import com.sun.tools.xjc.outline.ClassOutline;
import com.sun.tools.xjc.outline.Outline;
import com.sun.xml.bind.v2.WellKnownNamespace;
import com.sun.xml.xsom.XSDeclaration;

public class XSDStubGenerator extends MessagePartContentStubGenerator 
{
	private Map<QName, JType> mappings = new HashMap<QName, JType>();
	
	@Override
	public JType generate()
	{
		JType result = null;
		QName qualifiedElementName = null;
		try
		{
			checkElementList(getPartContent(), WellKnownNamespace.XML_SCHEMA, "schema");
			Element schemaElement = getPartContent().get(0);
			NodeList elementDefinitions = schemaElement.getElementsByTagNameNS(WellKnownNamespace.XML_SCHEMA, "element");
			if(elementDefinitions.getLength() != 1)
			{
				throw new RuntimeException("Schema must contain exactly ONE element definition");
			}
			else
			{
				Element element = (Element) elementDefinitions.item(0);
				writeDocumentToFile(element, new File("/home/doublemalt/riddletest.xml"));
				String elementTypeName = element.getAttribute("type");
				String[] elementTypeNameParts = elementTypeName.split(":");
				String localTypeName = elementTypeNameParts[1];
				String nsPrefix = elementTypeNameParts[0];
				String typeNameNSURI = element.lookupNamespaceURI(nsPrefix);
				qualifiedElementName = new QName(typeNameNSURI, localTypeName);
			}
			
			if(mappings.containsKey(qualifiedElementName))
			{
				return mappings.get(qualifiedElementName);
			}
			
			
			ErrorReceiver errorListener = new SysoutErrorReceiver();
			
			
			File schemaFile = null;
			if(schemaElement.getNamespaceURI().equals("http://www.w3.org/2001/XInclude"))
			{
				schemaFile = new File(schemaElement.getAttribute("href"));
			}
			else
			{
				schemaFile = new File(getBaseDirectory(), "part.xsd");
				writeDocumentToFile(schemaElement, schemaFile);
			}
			
			InputSource inputSource = new InputSource(schemaFile.toURI().toString());
	
			Options options = new Options();
			options.addGrammar(inputSource);
			options.automaticNameConflictResolution = true;
			options.setSchemaLanguage(Language.XMLSCHEMA);
			//options.defaultPackage = getPartPackage().name();
			options.verbose = true;
			//options.debugMode = true;
			
			Model xjcModel = ModelLoader.load(options, getCodeModel(), errorListener);
			Outline outline = xjcModel.generateCode(options, errorListener);
			for(ClassOutline generatedClass : outline.getClasses())
			{
				XSDeclaration typeDescription = (XSDeclaration) generatedClass.target.getSchemaComponent();
				
				QName qualifiedName = new QName(typeDescription.getTargetNamespace(), typeDescription.getName());
				mappings.put(qualifiedName, generatedClass.ref);
			}
			schemaFile.delete();
			
			result = mappings.get(qualifiedElementName);
			
		}
		catch(IOException e)
		{
			throw new RuntimeException(e);
		} catch (FactoryConfigurationError e) {
			throw new RuntimeException(e);
		} catch (Exception e) {
			throw new RuntimeException(e);		}
		
		return result;
	}

	private void checkElementList(List<Element> list, String namespace, String name) 
	{
		if(list.size() != 1)
		{
			throw new RuntimeException("Invalid XML! XML must consist of one and only one element!");
		} 
		else if(!list.get(0).getNamespaceURI().equals(namespace))
		{
			throw new RuntimeException("Invalid XML! Element must be from the Namespace " + namespace + " but is from " + list.get(0).getNamespaceURI() );
		}
		else if(!list.get(0).getTagName().equals(name))
		{
			throw new RuntimeException("Invalid XML! Element must be an '" + name + "'-tag but is a '" + list.get(0).getTagName() + "'-tag");
		}
	}

	@Override
	public String getURI() 
	{
		// TODO Auto-generated method stub
		return null;
	}
	
   public static void writeDocumentToFile(
            Node node, File file)
            throws Exception
         {
            FileOutputStream outStream =
               new FileOutputStream(file);
      
            TransformerFactory factory =
               TransformerFactory.newInstance();
            Transformer transformer = factory.newTransformer();
            transformer.setOutputProperty(
               OutputKeys.OMIT_XML_DECLARATION, "no");
            DOMSource source = new DOMSource(node);
            StreamResult result = new StreamResult(outStream);
            transformer.transform(source, result);
      
            outStream.close();
         }


}
