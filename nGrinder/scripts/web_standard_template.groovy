import static net.grinder.script.Grinder.grinder
import static org.hamcrest.Matchers.is
import static org.junit.Assert.assertThat

import groovy.json.JsonSlurper
import HTTPClient.CookieModule
import HTTPClient.CookiePolicyHandler
import HTTPClient.HTTPResponse
import HTTPClient.NVPair
import net.grinder.script.GTest
import net.grinder.script.engine.groovy.junit.GrinderRunner
import net.grinder.scriptengine.groovy.junit.annotation.BeforeProcess
import net.grinder.scriptengine.groovy.junit.annotation.BeforeThread
import net.grinder.scriptengine.groovy.junit.annotation.RunRate
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.ngrinder.http.HTTPRequest
import org.ngrinder.http.HTTPRequestControl

@RunWith(GrinderRunner)
class StandardWebFlow {

    public static GTest test
    public static HTTPRequest request
    public static NVPair[] headers = [
            new NVPair("Accept", "application/json"),
            new NVPair("Content-Type", "application/json")
    ] as NVPair[]

    static String requiredProperty(String name) {
        String value = System.getProperty(name)
        if (value == null || value.trim().isEmpty()) {
            throw new IllegalArgumentException("Required system property is not set: " + name)
        }
        return value
    }

    static String requiredUrlProperty(String name) {
        String value = requiredProperty(name)
        if (!(value.startsWith("http://") || value.startsWith("https://"))) {
            throw new IllegalArgumentException(name + " must start with http:// or https://")
        }
        return value.replaceAll("/+\$", "")
    }

    static String requiredPathProperty(String name) {
        String value = requiredProperty(name)
        if (!value.startsWith("/")) {
            throw new IllegalArgumentException(name + " must start with /")
        }
        return value
    }

    static String requiredJsonProperty(String name) {
        String value = requiredProperty(name)
        new JsonSlurper().parseText(value)
        return value
    }

    public static String BASE_URL = requiredUrlProperty("test.baseUrl")
    public static String HEALTH_PATH = requiredPathProperty("test.healthPath")
    public static String LOGIN_PATH = requiredPathProperty("test.loginPath")
    public static String LIST_PATH = requiredPathProperty("test.listPath")
    public static String DETAIL_PATH = requiredPathProperty("test.detailPath")
    public static String EVENT_PATH = requiredPathProperty("test.eventPath")
    public static String EVENT_PAYLOAD = requiredJsonProperty("test.eventPayload")
    public static String USERNAME = requiredProperty("test.username")
    public static String PASSWORD = requiredProperty("test.password")

    @BeforeProcess
    static void beforeProcess() {
        HTTPRequestControl.setConnectionTimeout(6000)
        HTTPRequestControl.setSocketTimeout(6000)
        CookieModule.setCookiePolicyHandler(CookiePolicyHandler.BROWSER_COMPATIBILITY)

        test = new GTest(1, "standard-web-flow")
        request = new HTTPRequest()
        test.record(request)

        grinder.logger.info("BASE_URL={}", BASE_URL)
    }

    @BeforeThread
    void beforeThread() {
        grinder.statistics.delayReports = true
        grinder.statistics.testNumber = 0
    }

    @Before
    void before() {
        grinder.logger.info("Run standard web flow")
    }

    @Test
    @RunRate(100)
    void testFlow() {
        HTTPResponse response = request.GET(BASE_URL + HEALTH_PATH, null)
        assertThat(response.statusCode, is(200))

        def body = "{\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}"
        response = request.POST(BASE_URL + LOGIN_PATH, body.getBytes("UTF-8"), headers)
        assertThat(response.statusCode, is(200))

        response = request.GET(BASE_URL + LIST_PATH, headers)
        assertThat(response.statusCode, is(200))

        response = request.GET(BASE_URL + DETAIL_PATH, headers)
        assertThat(response.statusCode, is(200))

        response = request.POST(BASE_URL + EVENT_PATH, EVENT_PAYLOAD.getBytes("UTF-8"), headers)
        assertThat(response.statusCode, is(200))
    }
}
