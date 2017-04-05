package ispyb.ws.rest.security.login;

import java.util.ArrayList;
import java.util.List;

public class ESRFLoginModule {
	
	
	public static List<String> authenticate(String username, String password)
			throws Exception {
		System.out.println("Dummy autnetication for docker. If you read this in production is because a big error somewhere");
		
		List<String> myRoles = new ArrayList<String>();
		myRoles.add("Manager");
		myRoles.add("User");
		return myRoles;
	}
}

