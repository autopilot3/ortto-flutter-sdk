package com.ortto.messaging.flutter

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertFalse
import org.junit.Test

/**
 * Guards the channel contract for identify: the keys here are exactly what
 * UserID.toMap() in ortto_flutter_sdk_platform_interface sends over the
 * channel. If either side renames a key, this test fails.
 */
class IdentifyMappingTest {

    @Test
    fun `maps every field from the snake_case keys dart sends`() {
        val args = mapOf(
            "first_name" to "Mitch",
            "last_name" to "Flindell",
            "accepts_gdpr" to true,
            "contact_id" to "contact-1",
            "email" to "mitch@example.com",
            "external_id" to "ext-9",
            "phone_number" to "+61400000000",
        )

        val user = OrttoFlutterSdkPlugin.userFromArguments(args)

        assertEquals("Mitch", user.firstName)
        assertEquals("Flindell", user.lastName)
        assertEquals(true, user.acceptsGdpr)
        assertEquals("contact-1", user.contactId)
        assertEquals("mitch@example.com", user.email)
        assertEquals("ext-9", user.externalId)
        assertEquals("+61400000000", user.phone)
    }

    @Test
    fun `missing fields stay null and gdpr defaults to false`() {
        val user = OrttoFlutterSdkPlugin.userFromArguments(mapOf("email" to "m@example.com"))

        assertEquals("m@example.com", user.email)
        assertNull(user.firstName)
        assertNull(user.lastName)
        assertNull(user.contactId)
        assertNull(user.externalId)
        assertNull(user.phone)
        assertFalse(user.acceptsGdpr)
    }
}
