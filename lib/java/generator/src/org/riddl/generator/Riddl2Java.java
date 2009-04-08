package org.riddl.generator;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBException;
import javax.xml.bind.Unmarshaller;
import javax.xml.bind.UnmarshallerHandler;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParserFactory;

import org.riddl.description.Description;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.XMLReader;

import com.elharo.xml.xinclude.XIncludeFilter;
import com.sun.codemodel.JClassAlreadyExistsException;
import com.sun.codemodel.JCodeModel;
import com.sun.codemodel.JPackage;

public class Riddl2Java
{
	/**
	 * @param args
	 * @throws JAXBException 
	 * @throws JClassAlreadyExistsException 
	 * @throws ClassNotFoundException 
	 * @throws IOException 
	 * @throws SAXException 
	 * @throws ParserConfigurationException 
	 */
	public static void main(String[] args) throws JAXBException, JClassAlreadyExistsException, ClassNotFoundException, IOException, SAXException, ParserConfigurationException 
	{
		File riddlDescription = new File(args[0]);
		File outputDirectory = new File(args[1]);
		String basePackage = args[2];
		
		String messagesPackageName = basePackage + ".messages";
		String resourcePackageName = basePackage + ".resources";
		
		JCodeModel codeModel = new JCodeModel();
		JPackage messagesPackage = codeModel._package(messagesPackageName);
		JPackage resourcePackage = codeModel._package(resourcePackageName);
		
		JAXBContext deserializationContext = JAXBContext.newInstance(Description.class);
		
		Unmarshaller unmarshaller = deserializationContext.createUnmarshaller();
		UnmarshallerHandler uh = unmarshaller.getUnmarshallerHandler();

		// create a parser
		SAXParserFactory spf = SAXParserFactory.newInstance();
		spf.setNamespaceAware(true);
		XMLReader xr = spf.newSAXParser().getXMLReader();

		// hook things up
		XIncludeFilter includer = new XIncludeFilter();
		includer.setParent(xr);
		includer.setContentHandler(uh);

		// and run!
		InputSource inputSource = new InputSource(new FileInputStream(riddlDescription));
		inputSource.setSystemId(riddlDescription.toURI().toString());
		includer.parse(inputSource);
		Description description = (Description) uh.getResult();
		
		RiddlDescriptionGenerator riddlDescriptionGenerator = new RiddlDescriptionGenerator();
		riddlDescriptionGenerator.setMessagesPackage(messagesPackage);
		riddlDescriptionGenerator.setResourcePackage(resourcePackage);
		riddlDescriptionGenerator.setJCodeModel(codeModel);
		riddlDescriptionGenerator.setDescription(description);
		riddlDescriptionGenerator.setBaseDirectory(riddlDescription.getParentFile());
		riddlDescriptionGenerator.generateRiddleDecriptionStubs();
		codeModel.build(outputDirectory);
	}


	

	

	

}
