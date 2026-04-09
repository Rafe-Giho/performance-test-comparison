import static net.grinder.script.Grinder.grinder
import static org.hamcrest.Matchers.is
import static org.junit.Assert.assertThat

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

    public static String BASE_URL = System.getProperty("test.baseUrl", "https://example.com")
    public static String HEALTH_PATH = System.getProperty("test.healthPath", "/health")
    public static String LOGIN_PATH = System.getProperty("test.loginPath", "/api/login")
    public static String LIST_PATH = System.getProperty("test.listPath", "/api/items")
    public static String DETAIL_PATH = System.getProperty("test.detailPath", "/api/items/1")
    public static String USERNAME = System.getProperty("test.username", "user01")
    public static String PASSWORD = System.getProperty("test.password", "pass01")

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
    }
}
