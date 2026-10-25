package com.ops.banking_ops_copilot.monitoring.repository;

import com.ops.banking_ops_copilot.monitoring.entity.DataFeed;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface DataFeedRepository extends JpaRepository<DataFeed, Long> {
    Optional<DataFeed> findByFeedCode(String feedCode);
}

