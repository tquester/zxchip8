/*
 *  Licensed to the Apache Software Foundation (ASF) under one
 *  or more contributor license agreements.  See the NOTICE file
 *  distributed with this work for additional information
 *  regarding copyright ownership.  The ASF licenses this file
 *  to you under the Apache License, Version 2.0 (the
 *  "License"); you may not use this file except in compliance
 *  with the License.  You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */
package domainapp.modules.simple.dom.impl;

import javax.jdo.annotations.IdGeneratorStrategy;
import javax.jdo.annotations.IdentityType;
import javax.jdo.annotations.VersionStrategy;
import javax.xml.bind.annotation.adapters.XmlJavaTypeAdapter;

import com.google.common.collect.ComparisonChain;

import org.apache.isis.applib.annotation.Action;
import org.apache.isis.applib.annotation.Auditing;
import org.apache.isis.applib.annotation.DomainObject;
import org.apache.isis.applib.annotation.DomainObjectLayout;
import org.apache.isis.applib.annotation.Publishing;
import org.apache.isis.applib.services.message.MessageService;
import org.apache.isis.applib.services.repository.RepositoryService;
import org.apache.isis.applib.services.title.TitleService;
import org.apache.isis.schema.utils.jaxbadapters.PersistentEntityAdapter;

import domainapp.modules.simple.dom.types.Name;
import domainapp.modules.simple.dom.types.Notes;
import static org.apache.isis.applib.annotation.CommandReification.ENABLED;
import static org.apache.isis.applib.annotation.SemanticsOf.IDEMPOTENT;
import static org.apache.isis.applib.annotation.SemanticsOf.NON_IDEMPOTENT_ARE_YOU_SURE;

@javax.jdo.annotations.PersistenceCapable(identityType=IdentityType.DATASTORE, schema = "simple")
@javax.jdo.annotations.DatastoreIdentity(strategy=IdGeneratorStrategy.IDENTITY, column="id")
@javax.jdo.annotations.Version(strategy= VersionStrategy.DATE_TIME, column="version")
@javax.jdo.annotations.Unique(name="SimpleObject_name_UNQ", members = {"name"})
@DomainObject(auditing = Auditing.ENABLED)
@DomainObjectLayout()  // causes UI events to be triggered
@lombok.RequiredArgsConstructor
@XmlJavaTypeAdapter(PersistentEntityAdapter.class)
public class SimpleObject implements Comparable<SimpleObject> {

    public String title() {
        return "Object: " + getName();
    }

    @lombok.Getter @lombok.Setter @lombok.NonNull
    @Name private String name;

    @lombok.Getter @lombok.Setter
    @Notes private String notes;


    @Action(semantics = IDEMPOTENT, command = ENABLED, publishing = Publishing.ENABLED, associateWith = "name")
    public SimpleObject updateName(
            @Name final String name) {
        setName(name);
        return this;
    }
    public String default0UpdateName() {
        return getName();
    }


    @Action(semantics = NON_IDEMPOTENT_ARE_YOU_SURE)
    public void delete() {
        final String title = titleService.titleOf(this);
        messageService.informUser(String.format("'%s' deleted", title));
        repositoryService.removeAndFlush(this);
    }

    @Override
    public String toString() {
        return getName();
    }

    @Override
    public int compareTo(final SimpleObject other) {
        return ComparisonChain.start()
                .compare(this.getName(), other.getName())
                .result();
    }


    @javax.inject.Inject
    @javax.jdo.annotations.NotPersistent
    RepositoryService repositoryService;

    @javax.inject.Inject
    @javax.jdo.annotations.NotPersistent
    TitleService titleService;

    @javax.inject.Inject
    @javax.jdo.annotations.NotPersistent
    MessageService messageService;

}