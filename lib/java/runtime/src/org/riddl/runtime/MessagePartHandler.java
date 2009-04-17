package org.riddl.runtime;

import com.sun.jersey.multipart.BodyPart;

public interface MessagePartHandler 
{
	Object createMessageFromBodyPart(BodyPart bodyPart);

}
