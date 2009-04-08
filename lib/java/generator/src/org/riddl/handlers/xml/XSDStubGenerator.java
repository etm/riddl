package org.riddl.handlers.xml;


import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;

import javax.xml.stream.FactoryConfigurationError;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.riddl.generator.MessagePartContentStubGenerator;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.xml.sax.InputSource;
import org.xml.sax.SAXParseException;

import com.sun.codemodel.JType;
import com.sun.tools.xjc.AbortException;
import com.sun.tools.xjc.ErrorReceiver;
import com.sun.tools.xjc.Language;
import com.sun.tools.xjc.ModelLoader;
import com.sun.tools.xjc.Options;
import com.sun.tools.xjc.model.Model;
import com.sun.tools.xjc.outline.Outline;

public class XSDStubGenerator extends MessagePartContentStubGenerator 
{

	@Override
	public JType generate()
	{
		JType result = null;
		try
		{
			if(getPartContent().size() != 1)
			{
				throw new RuntimeException("Invalid Schema!");
			}
			
			
			ErrorReceiver errorListener = new ErrorReceiver() {
			
				@Override
				public void warning(SAXParseException exception) throws AbortException {
					System.out.println("WARNING: " + exception.getLineNumber() + " - " + exception.getMessage());
			
				}
			
				@Override
				public void info(SAXParseException exception) {
					System.out.println("INFO: " + exception.getLineNumber() + " - " + exception.getMessage());
			
				}
			
				@Override
				public void fatalError(SAXParseException exception) throws AbortException {
					System.out.println("FATAL: " + exception.getLineNumber() + " - " + exception.getMessage());
					System.out.println(exception.getColumnNumber());
			
				}
			
				@Override
				public void error(SAXParseException exception) throws AbortException {
					System.out.println("ERROR: " + exception.getLineNumber() + " - " + exception.getMessage());
			
				}
			};
			
			Element schemaElement = getPartContent().get(0);
			
			
			File schemaFile = null;
			if(schemaElement.getNamespaceURI().equals("http://www.w3.org/2001/XInclude"))
			{
				schemaFile = new File(schemaElement.getAttribute("href"));
			}
			else
			{
				schemaFile = new File(getBaseDirectory(), "part.xsd");
				writeDocumentToFile(getPartContent().get(0), schemaFile);
			}
			
			InputSource inputSource = new InputSource(schemaFile.toURI().toString());
	
			Options options = new Options();
			options.addGrammar(inputSource);
			options.automaticNameConflictResolution = true;
			options.setSchemaLanguage(Language.XMLSCHEMA);
			options.defaultPackage = getPartPackage().name();
			options.verbose = true;
			//options.debugMode = true;
			
			Model xjcModel = ModelLoader.load(options, getCodeModel(), errorListener);
			xjcModel.getSymbolSpace("");
			Outline outline = xjcModel.generateCode(options, errorListener);
			result = outline.getClasses().iterator().next().ref;
			
			schemaFile.delete();
			
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
